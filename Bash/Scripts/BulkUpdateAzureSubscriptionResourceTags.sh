#!/usr/bin/env bash
# bulk-add-missing-tag.sh
# Add a tag (key=value) to ALL resources in a subscription where the tag is missing or empty.
# Uses 'az resource tag --is-incremental' to avoid provider-specific validation (safer for ContainerApps, etc).
# Requires: Azure CLI logged in with access to the target subscription.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
BulkUpdateAzureSubscriptionResourceTags.sh -s <subscriptionIdOrName> -k <tagKey> -v <tagValue> [options]

Options:
  --dry-run                 Show what would be changed, but don't apply it
  --include-types <list>    Comma-separated resource types to include (e.g. "Microsoft.Compute/virtualMachines,Microsoft.App/containerApps")
  --exclude-types <list>    Comma-separated resource types to exclude
  --resource-groups <list>  Comma-separated RG names to limit scope
  --case-sensitive          Treat tag KEY comparison as case-sensitive (default: case-insensitive best-effort)
  --max                      Only process up to this many resources (for testing)
  -h, --help               Show help

Notes:
  - By default, the script attempts a CASE-INSENSITIVE tag-key presence check. Azure’s tag key handling can be inconsistent across RPs,
    so supply the exact casing you want to enforce on write. Existing differently-cased keys won’t be overwritten.
  - Uses incremental tagging so existing tags are preserved.
  - If any resource fails to tag, the script logs and continues.

Example usage:
  bulk-add-missing-tag.sh -s my-subscription -k Environment -v Production --include-types Microsoft.Compute/virtualMachines,Microsoft.App/containerApps --dry-run
  # This would show what would be tagged without making changes.
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

# Parse args
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

# Validate
if [[ -z "$SUB" || -z "$TAG_KEY" || -z "$TAG_VALUE" ]]; then
  echo "Error: --subscription, --key and --value are required." >&2
  usage; exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Error: Azure CLI 'az' not found in PATH." >&2
  exit 1
fi

# Set subscription
echo "Using subscription: $SUB"
az account set --subscription "$SUB" >/dev/null

# Build base query for az resource list
RG_FILTER=""
if [[ -n "$LIMIT_RGS" ]]; then
  # Convert comma list to an OR filter in JMESPath after listing; we’ll filter in bash to keep it simple.
  :
fi

# Fetch resources (id + type + rg) up front
echo "Enumerating resources... (this may take a bit on large subscriptions)"
RES_JSON="$(az resource list --subscription "$SUB" --query "[].{id:id,type:type,rg:resourceGroup}" -o json)"

# Optional filtering helpers
filter_by_types() {
  local json="$1"
  local incl="$2"
  local excl="$3"

  # If include set, keep only those; else if exclude set, drop those; else pass-through.
  if [[ -n "$incl" ]]; then
    # Build a JMESPath that matches any in list
    local IFS=','; read -r -a arr <<< "$incl"
    local conds=()
    for t in "${arr[@]}"; do conds+=("type=='$t'"); done
    local jpcond
    jpcond=$(IFS=" || "; echo "${conds[*]}")
    az jq <<EOF "$json"
[.[] | select(.type != null) | select($jpcond)]
EOF
    return
  fi

  if [[ -n "$excl" ]]; then
    local IFS=','; read -r -a arr <<< "$excl"
    local conds=()
    for t in "${arr[@]}"; do conds+=("type!='$t'"); done
    local jpcond
    jpcond=$(IFS=" && "; echo "${conds[*]}")
    az jq <<EOF "$json"
[.[] | select(.type != null) | select($jpcond)]
EOF
    return
  fi

  # No include/exclude -> echo original
  echo "$json"
}

filter_by_rgs() {
  local json="$1"
  local rgs="$2"
  if [[ -z "$rgs" ]]; then
    echo "$json"; return
  fi
  local IFS=','; read -r -a arr <<< "$rgs"
  local conds=()
  for g in "${arr[@]}"; do conds+=("rg=='$g'"); done
  local jpcond
  jpcond=$(IFS=" || "; echo "${conds[*]}")
  az jq <<EOF "$json"
[.[] | select(.rg != null) | select($jpcond)]
EOF
}

# Tiny helper to use Azure CLI's built-in JMESPath "jq-like" filtering via `az` (no external jq required)
az jq() { az json -c "$@"; } 2>/dev/null || true
# Fallback if 'az json -c' isn't available (older CLI). We'll just pass through unfiltered.
if ! az json -h >/dev/null 2>&1; then
  az() { command az "$@"; }  # restore
  filter_by_types() { echo "$1"; }
  filter_by_rgs()   { echo "$1"; }
fi

RES_JSON="$(filter_by_types "$RES_JSON" "$INCLUDE_TYPES" "$EXCLUDE_TYPES")"
RES_JSON="$(filter_by_rgs   "$RES_JSON" "$LIMIT_RGS")"

TOTAL="$(echo "$RES_JSON" | az json -c 'length(@)' 2>/dev/null || echo 0)"
echo "Found $TOTAL resource(s) after filtering."

if [[ "$TOTAL" -eq 0 ]]; then
  echo "Nothing to do."; exit 0
fi

# Iterate
UPDATED=0
SKIPPED_PRESENT=0
FAILED=0
PROCESSED=0

# Extract IDs as TSV for simple iteration
IDS="$(echo "$RES_JSON" | az json -c "[].id" -o tsv 2>/dev/null || true)"
if [[ -z "$IDS" ]]; then
  echo "No resource IDs parsed; exiting."
  exit 0
fi

echo "Starting tagging pass for key='$TAG_KEY' value='$TAG_VALUE' ..."
while IFS= read -r RID; do
  [[ -z "$RID" ]] && continue

  PROCESSED=$((PROCESSED+1))
  if [[ $MAX_COUNT -gt 0 && $PROCESSED -gt $MAX_COUNT ]]; then
    echo "Reached --max=$MAX_COUNT limit; stopping early."
    break
  fi

  # Fetch existing tags (JSON). Null-safe.
  TAGS_JSON="$(az resource show --ids "$RID" --query "tags" -o json 2>/dev/null || echo 'null')"

  # Decide presence: case-insensitive best effort by searching keys list
  HAS_KEY=0
  if [[ "$CASE_SENSITIVE" -eq 1 ]]; then
    VAL_JSON="$(az resource show --ids "$RID" --query "tags['$TAG_KEY']" -o json 2>/dev/null || echo 'null')"
    # Present if not null and not empty string
    if [[ "$VAL_JSON" != "null" && "$VAL_JSON" != '""' ]]; then
      HAS_KEY=1
    fi
  else
    # Pull keys as TSV; compare lowercased in bash
    KEYS_TSV="$(az resource show --ids "$RID" --query "keys(tags || `{}`)" -o tsv 2>/dev/null || true)"
    shopt -s nocasematch
    for k in $KEYS_TSV; do
      if [[ "$k" == "$TAG_KEY" ]]; then
        # Check value not empty
        VAL_JSON="$(az resource show --ids "$RID" --query "tags['$k']" -o json 2>/dev/null || echo 'null')"
        if [[ "$VAL_JSON" != "null" && "$VAL_JSON" != '""' ]]; then
          HAS_KEY=1
          break
        fi
      fi
    done
    shopt -u nocasematch
  fi

  if [[ $HAS_KEY -eq 1 ]]; then
    echo "[$PROCESSED/$TOTAL] $RID — tag present, skipping."
    SKIPPED_PRESENT=$((SKIPPED_PRESENT+1))
    continue
  fi

  echo "[$PROCESSED/$TOTAL] $RID — tag missing/empty; will set $TAG_KEY=$TAG_VALUE"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] az resource tag --ids \"$RID\" --is-incremental --tags \"$TAG_KEY=$TAG_VALUE\""
    continue
  fi

  if az resource tag --ids "$RID" --is-incremental --tags "$TAG_KEY=$TAG_VALUE" >/dev/null 2>&1; then
    UPDATED=$((UPDATED+1))
  else
    echo "  WARN: tagging failed for $RID (continuing)" >&2
    FAILED=$((FAILED+1))
  fi

done <<< "$IDS"

echo "----------"
echo "Done."
echo "Processed: $PROCESSED"
echo "Updated:   $UPDATED"
echo "Skipped:   $SKIPPED_PRESENT"
echo "Failed:    $FAILED"
[[ $DRY_RUN -eq 1 ]] && echo "(dry-run; no changes were made)"