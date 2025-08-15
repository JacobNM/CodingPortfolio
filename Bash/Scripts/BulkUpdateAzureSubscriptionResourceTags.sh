#!/usr/bin/env bash
# BulkUpdateAzureSubscriptionResourceTags.sh
# Add a tag key=value to every resource in a subscription where the key is missing or empty.
# Uses: az resource tag --is-incremental (preserves existing tags; avoids RP validation issues)

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  BulkUpdateAzureSubscriptionResourceTags.sh -s <subscriptionIdOrName> -k <tagKey> -v <tagValue> [options]

Options:
  --dry-run                 Show what would be changed, but don't apply it
  --include-types <list>    Comma-separated resource types to include
  --exclude-types <list>    Comma-separated resource types to exclude
  --resource-groups <list>  Comma-separated RG names to limit scope
  --case-sensitive          Treat tag-key detection as case-sensitive (default: best-effort case-insensitive)
  --max <N>                 Process at most N resources (useful for testing)
  -h, --help                Show help

Example usages:
  BulkUpdateAzureSubscriptionResourceTags.sh -s my-subscription -k Environment -v Production --include-types Microsoft.Compute/virtualMachines,Microsoft.App/containerApps --dry-run
  # This would show what would be tagged without making changes.

  ./BulkUpdateAzureSubscriptionResourceTags.sh -s "MyProdSub" -k environment -v prod --exclude-types "Microsoft.KeyVault/vaults"
    # This would tag all resources except Key Vaults, adding 'environment=prod' where missing/empty.

  ./BulkUpdateAzureSubscriptionResourceTags.sh -s "MyProdSub" -k environment -v prod --resource-groups "MyResourceGroup"
    # This would only tag resources in "MyResourceGroup" with 'environment=prod' where missing/empty.

  ./BulkUpdateAzureSubscriptionResourceTags.sh -s "MyProdSub" -k environment -v prod --max 25
    # This would tag up to 25 resources in the subscription with 'environment=prod' where missing/empty.
EOF
}

SUB=""
TAG_KEY=""
TAG_VALUE=""
DRY_RUN=0
INCLUDE_TYPES=""
EXCLUDE_TYPES=""
LIMIT_RGS=""
CASE_SENSITIVE=0
MAX_COUNT=0

# ---- arg parse ----
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--subscription) SUB="$2"; shift 2 ;;
    -k|--key)          TAG_KEY="$2"; shift 2 ;;
    -v|--value)        TAG_VALUE="$2"; shift 2 ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --include-types)   INCLUDE_TYPES="$2"; shift 2 ;;
    --exclude-types)   EXCLUDE_TYPES="$2"; shift 2 ;;
    --resource-groups) LIMIT_RGS="$2"; shift 2 ;;
    --case-sensitive)  CASE_SENSITIVE=1; shift ;;
    --max)             MAX_COUNT="${2:-0}"; shift 2 ;;
    -h|--help)         usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$SUB" || -z "$TAG_KEY" || -z "$TAG_VALUE" ]]; then
  echo "Error: --subscription, --key, and --value are required." >&2
  usage; exit 1
fi

command -v az >/dev/null 2>&1 || { echo "Error: Azure CLI 'az' not found."; exit 1; }

echo "Using subscription: $SUB"
az account set --subscription "$SUB" >/dev/null

# ---- Build JMESPath filter for az resource list ----
# Start with conditions array, join with && where appropriate
jmes_filters=()

# Include types: OR across provided types
if [[ -n "$INCLUDE_TYPES" ]]; then
  IFS=',' read -r -a inc_arr <<< "$INCLUDE_TYPES"
  type_conds=()
  for t in "${inc_arr[@]}"; do
    t_trim="${t#"${t%%[![:space:]]*}"}"; t_trim="${t_trim%"${t_trim##*[![:space:]]}"}"
    [[ -n "$t_trim" ]] && type_conds+=("type=='$t_trim'")
  done
  if [[ ${#type_conds[@]} -gt 0 ]]; then
    jmes_filters+=("(${type_conds[*]// / })")  # ORs will be joined later
  fi
fi

# Resource groups: OR across provided RGs
if [[ -n "$LIMIT_RGS" ]]; then
  IFS=',' read -r -a rg_arr <<< "$LIMIT_RGS"
  rg_conds=()
  for g in "${rg_arr[@]}"; do
    g_trim="${g#"${g%%[![:space:]]*}"}"; g_trim="${g_trim%"${g_trim##*[![:space:]]}"}"
    [[ -n "$g_trim" ]] && rg_conds+=("resourceGroup=='$g_trim'")
  done
  if [[ ${#rg_conds[@]} -gt 0 ]]; then
    jmes_filters+=("(${rg_conds[*]// / })")
  fi
fi

# Join includes with OR inside each group, then AND across groups
# We constructed each group as "(cond || cond)", but we stored with spaces; fix joins explicitly:
# Replace spaces between OR terms with ' || ' and between groups with ' && '
filter_expr=""
if [[ ${#jmes_filters[@]} -gt 0 ]]; then
  # Each group currently "(a||b)"? Ensure proper '||'
  cleaned=()
  for grp in "${jmes_filters[@]}"; do
    grp="${grp//)||/ ) || ( }" # no-op safeguard
    # We built using spaces; rebuild ORs correctly:
    grp="${grp//) (/ ) || ( }"
    cleaned+=("$grp")
  done
  # AND across groups
  filter_expr="$(IFS=' && '; echo "${cleaned[*]}")"
fi

# Base query
if [[ -n "$filter_expr" ]]; then
  LIST_QUERY="[? $filter_expr ].{id:id,type:type,rg:resourceGroup}"
else
  LIST_QUERY="[].{id:id,type:type,rg:resourceGroup}"
fi

echo "Enumerating resources... (this may take a bit on large subscriptions)"
RES_JSON="$(az resource list --query "$LIST_QUERY" -o json)"

# If we also got exclude types, drop them in bash
if [[ -n "$EXCLUDE_TYPES" ]]; then
  IFS=',' read -r -a exc_arr <<< "$EXCLUDE_TYPES"
else
  exc_arr=()
fi

# Extract IDs to iterate
mapfile -t IDS < <(echo "$RES_JSON" | az jq --query "[].id" -o tsv 2>/dev/null || true)
# Fallback if 'az jq' isn’t available; use standard az to print via loop
if [[ ${#IDS[@]} -eq 0 ]]; then
  IDS=()
  while IFS= read -r id; do [[ -n "$id" ]] && IDS+=("$id"); done < <(az resource list --query "$LIST_QUERY[].id" -o tsv 2>/dev/null || true)
fi

TOTAL="${#IDS[@]}"
echo "Found $TOTAL resource(s) after filtering."

if [[ "$TOTAL" -eq 0 ]]; then
  echo "Nothing to do."; exit 0
fi

UPDATED=0; SKIPPED_PRESENT=0; FAILED=0; PROCESSED=0

echo "Starting tagging pass for key='$TAG_KEY' value='$TAG_VALUE' ..."
for RID in "${IDS[@]}"; do
  ((PROCESSED++))
  if [[ $MAX_COUNT -gt 0 && $PROCESSED -gt $MAX_COUNT ]]; then
    echo "Reached --max=$MAX_COUNT limit; stopping early."
    break
  fi

  # Skip excluded types if requested
  if [[ ${#exc_arr[@]} -gt 0 ]]; then
    RTYPE="$(az resource show --ids "$RID" --query type -o tsv 2>/dev/null || echo "")"
    for xt in "${exc_arr[@]}"; do
      if [[ "$RTYPE" == "$xt" ]]; then
        echo "[$PROCESSED/$TOTAL] $RID — excluded type '$RTYPE', skipping."
        continue 2
      fi
    done
  fi

  # Pull keys(tags) to detect presence (null-safe)
  KEYS_TSV="$(az resource show --ids "$RID" --query "keys(tags || `{}`)" -o tsv 2>/dev/null || true)"

  HAS_KEY=0
  if [[ "$CASE_SENSITIVE" -eq 1 ]]; then
    for k in $KEYS_TSV; do
      if [[ "$k" == "$TAG_KEY" ]]; then
        VAL_JSON="$(az resource show --ids "$RID" --query "tags['$k']" -o json 2>/dev/null || echo 'null')"
        if [[ "$VAL_JSON" != "null" && "$VAL_JSON" != '""' ]]; then HAS_KEY=1; fi
        break
      fi
    done
  else
    tk_lc="$(echo -n "$TAG_KEY" | tr 'A-Z' 'a-z')"
    for k in $KEYS_TSV; do
      klc="$(echo -n "$k" | tr 'A-Z' 'a-z')"
      if [[ "$klc" == "$tk_lc" ]]; then
        VAL_JSON="$(az resource show --ids "$RID" --query "tags['$k']" -o json 2>/dev/null || echo 'null')"
        if [[ "$VAL_JSON" != "null" && "$VAL_JSON" != '""' ]]; then HAS_KEY=1; fi
        break
      fi
    done
  fi

  if [[ $HAS_KEY -eq 1 ]]; then
    echo "[$PROCESSED/$TOTAL] $RID — tag present, skipping."
    ((SKIPPED_PRESENT++))
    continue
  fi

  echo "[$PROCESSED/$TOTAL] $RID — tag missing/empty; will set $TAG_KEY=$TAG_VALUE"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] az resource tag --ids \"$RID\" --is-incremental --tags \"$TAG_KEY=$TAG_VALUE\""
    continue
  fi

  if az resource tag --ids "$RID" --is-incremental --tags "$TAG_KEY=$TAG_VALUE" >/dev/null 2>&1; then
    ((UPDATED++))
  else
    echo "  WARN: tagging failed for $RID (continuing)" >&2
    ((FAILED++))
  fi
done

echo "----------"
echo "Done."
echo "Processed: $PROCESSED"
echo "Updated:   $UPDATED"
echo "Skipped:   $SKIPPED_PRESENT"
echo "Failed:    $FAILED"
[[ $DRY_RUN -eq 1 ]] && echo "(dry-run; no changes were made)"