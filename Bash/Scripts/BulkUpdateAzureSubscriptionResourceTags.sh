#!/usr/bin/env bash
# BulkUpdateAzureSubscriptionResourceTags.sh
# Add tag key=value to resources missing/empty across a subscription.
# Uses only bash + Azure CLI; no mapfile/jq required.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  BulkUpdateAzureSubscriptionResourceTags.sh -s <subscriptionIdOrName> -k <tagKey> -v <tagValue> [options]

Options:
  --dry-run                 Show actions without applying
  --include-types <list>    Comma-separated types to include
  --exclude-types <list>    Comma-separated types to exclude
  --resource-groups <list>  Comma-separated RG names to include
  --case-sensitive          Strict tag-key match (default: case-insensitive)
  --max <N>                 Process at most N resources
  -h, --help                Show help

Notes:
  - <subscriptionIdOrName> is the Azure subscription ID or name.
  - <tagKey> and <tagValue> are the tag key and value to set.
  - Uses 'az resource tag --is-incremental' to avoid provider validation errors.
  - Preserves all existing tags; only adds the missing key.

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

while [ $# -gt 0 ]; do
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

if [ -z "$SUB" ] || [ -z "$TAG_KEY" ] || [ -z "$TAG_VALUE" ]; then
  echo "Error: --subscription, --key, and --value are required." >&2
  usage; exit 1
fi

command -v az >/dev/null 2>&1 || { echo "Error: Azure CLI 'az' not found."; exit 1; }

echo "Using subscription: $SUB"
az account set --subscription "$SUB" >/dev/null

# Build JMESPath filter
cond_type=""
if [ -n "$INCLUDE_TYPES" ]; then
  IFS=','; set -f
  type_conds=""
  for t in $INCLUDE_TYPES; do
    t=$(printf "%s" "$t" | xargs)  # trim
    [ -n "$t" ] && { [ -z "$type_conds" ] && type_conds="type=='$t'" || type_conds="$type_conds || type=='$t'"; }
  done
  set +f
  [ -n "$type_conds" ] && cond_type="($type_conds)"
fi

cond_rg=""
if [ -n "$LIMIT_RGS" ]; then
  IFS=','; set -f
  rg_conds=""
  for g in $LIMIT_RGS; do
    g=$(printf "%s" "$g" | xargs)
    [ -n "$g" ] && { [ -z "$rg_conds" ] && rg_conds="resourceGroup=='$g'" || rg_conds="$rg_conds || resourceGroup=='$g'"; }
  done
  set +f
  [ -n "$rg_conds" ] && cond_rg="($rg_conds)"
fi

filter_expr=""
if [ -n "$cond_type" ] && [ -n "$cond_rg" ]; then
  filter_expr="$cond_type && $cond_rg"
elif [ -n "$cond_type" ]; then
  filter_expr="$cond_type"
elif [ -n "$cond_rg" ]; then
  filter_expr="$cond_rg"
fi

if [ -n "$filter_expr" ]; then
  LIST_QUERY="[? $filter_expr ].{id:id,type:type,rg:resourceGroup}"
else
  LIST_QUERY="[].{id:id,type:type,rg:resourceGroup}"
fi

echo "Enumerating resources..."
# Stream just the IDs (TSV), so we can iterate without arrays/mapfile.
# shellcheck disable=SC2016
ID_QUERY="$LIST_QUERY[].id"
IDS_FILE="$(mktemp)"
trap 'rm -f "$IDS_FILE"' EXIT

if ! az resource list --query "$ID_QUERY" -o tsv > "$IDS_FILE"; then
  echo "Error: failed to list resources." >&2
  exit 1
fi

TOTAL=$(wc -l < "$IDS_FILE" | tr -d ' ')
echo "Found $TOTAL resource(s) after filtering."

# Prepare exclude list array
EXC_TYPES=""
if [ -n "$EXCLUDE_TYPES" ]; then
  IFS=','; set -f
  for xt in $EXCLUDE_TYPES; do
    xt=$(printf "%s" "$xt" | xargs)
    [ -n "$xt" ] && EXC_TYPES="$EXC_TYPES|$xt|"
  done
  set +f
fi

UPDATED=0; SKIPPED_PRESENT=0; FAILED=0; PROCESSED=0

echo "Starting tagging pass for key='$TAG_KEY' value='$TAG_VALUE' ..."
# Read IDs line-by-line (portable; no mapfile).
while IFS= read -r RID; do
  [ -z "$RID" ] && continue
  PROCESSED=$((PROCESSED+1))
  if [ "$MAX_COUNT" -gt 0 ] && [ "$PROCESSED" -gt "$MAX_COUNT" ]; then
    echo "Reached --max=$MAX_COUNT limit; stopping early."
    break
  fi

  # Exclude types if requested
  if [ -n "$EXC_TYPES" ]; then
    RTYPE="$(az resource show --ids "$RID" --query type -o tsv 2>/dev/null || echo "")"
    case "$EXC_TYPES" in
      *"|$RTYPE|"*) echo "[$PROCESSED/$TOTAL] $RID — excluded type '$RTYPE', skipping."; continue ;;
    esac
  fi

  # Get existing tag keys (safe if null)
  KEYS_TSV="$(az resource show --ids "$RID" --query "keys(tags || `{}`)" -o tsv 2>/dev/null || true)"

  HAS_KEY=0
  if [ "$CASE_SENSITIVE" -eq 1 ]; then
    for k in $KEYS_TSV; do
      if [ "$k" = "$TAG_KEY" ]; then
        VAL_JSON="$(az resource show --ids "$RID" --query "tags['$k']" -o json 2>/dev/null || echo 'null')"
        if [ "$VAL_JSON" != "null" ] && [ "$VAL_JSON" != '""' ]; then HAS_KEY=1; fi
        break
      fi
    done
  else
    tk_lc="$(printf "%s" "$TAG_KEY" | tr 'A-Z' 'a-z')"
    for k in $KEYS_TSV; do
      klc="$(printf "%s" "$k" | tr 'A-Z' 'a-z')"
      if [ "$klc" = "$tk_lc" ]; then
        VAL_JSON="$(az resource show --ids "$RID" --query "tags['$k']" -o json 2>/dev/null || echo 'null')"
        if [ "$VAL_JSON" != "null" ] && [ "$VAL_JSON" != '""' ]; then HAS_KEY=1; fi
        break
      fi
    done
  fi

  if [ $HAS_KEY -eq 1 ]; then
    echo "[$PROCESSED/$TOTAL] $RID — tag present, skipping."
    SKIPPED_PRESENT=$((SKIPPED_PRESENT+1))
    continue
  fi

  echo "[$PROCESSED/$TOTAL] $RID — tag missing/empty; will set $TAG_KEY=$TAG_VALUE"
  if [ $DRY_RUN -eq 1 ]; then
    echo "  [dry-run] az resource tag --ids \"$RID\" --is-incremental --tags \"$TAG_KEY=$TAG_VALUE\""
    continue
  fi

  if az resource tag --ids "$RID" --is-incremental --tags "$TAG_KEY=$TAG_VALUE" >/dev/null 2>&1; then
    UPDATED=$((UPDATED+1))
  else
    echo "  WARN: tagging failed for $RID (continuing)" >&2
    FAILED=$((FAILED+1))
  fi
done < "$IDS_FILE"

echo "----------"
echo "Done."
echo "Processed: $PROCESSED"
echo "Updated:   $UPDATED"
echo "Skipped:   $SKIPPED_PRESENT"
echo "Failed:    $FAILED"
[ $DRY_RUN -eq 1 ] && echo "(dry-run; no changes were made)"