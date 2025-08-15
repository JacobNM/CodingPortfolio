#!/usr/bin/env bash
# UpdateAzureResourceWithTag.sh
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  # With full resource ID
  UpdateAzureResourceWithTag.sh -i <resourceId> -k <tagKey> -v <tagValue> [--dry-run]

  # Or with RG/Name/Type
  UpdateAzureResourceWithTag.sh -g <resourceGroup> -n <name> -t <resourceType> -k <tagKey> -v <tagValue> [--dry-run]

Notes:
  - <resourceType> example: Microsoft.App/containerApps (case-insensitive)
  - Preserves all existing tags; only adds the missing key.
  - Uses 'az resource tag --is-incremental' to avoid provider validation errors.
EOF
}

RESOURCE_ID=""
RG=""
NAME=""
TYPE=""
TAG_KEY=""
TAG_VALUE=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--id) RESOURCE_ID="$2"; shift 2 ;;
    -g|--resource-group) RG="$2"; shift 2 ;;
    -n|--name) NAME="$2"; shift 2 ;;
    -t|--type) TYPE="$2"; shift 2 ;;
    -k|--key) TAG_KEY="$2"; shift 2 ;;
    -v|--value) TAG_VALUE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$TAG_KEY" || -z "$TAG_VALUE" ]]; then
  echo "Error: tag key and value are required." >&2
  usage; exit 1
fi

if [[ -z "$RESOURCE_ID" && ( -z "$RG" || -z "$NAME" || -z "$TYPE" ) ]]; then
  echo "Error: either --id or (--resource-group, --name, --type) must be provided." >&2
  usage; exit 1
fi

command -v az >/dev/null 2>&1 || { echo "Error: Azure CLI 'az' not found."; exit 1; }

if [[ -z "$RESOURCE_ID" ]]; then
  RESOURCE_ID="$(az resource show --resource-group "$RG" --name "$NAME" --resource-type "$TYPE" --query id -o tsv)"
  [[ -n "$RESOURCE_ID" ]] || { echo "Error: failed to resolve resource ID."; exit 1; }
fi

echo "Target resource: $RESOURCE_ID"
echo "Ensuring tag: $TAG_KEY=$TAG_VALUE"

# Read current value safely as JSON (handles null)
CURRENT_JSON="$(az resource show --ids "$RESOURCE_ID" --query "tags.${TAG_KEY}" -o json || echo 'null')"
# Strip surrounding quotes if it's a JSON string; null stays "null"
CURRENT_VALUE="${CURRENT_JSON%\"}"; CURRENT_VALUE="${CURRENT_VALUE#\"}"

if [[ "$CURRENT_JSON" != "null" && -n "$CURRENT_VALUE" ]]; then
  echo "Tag '$TAG_KEY' already present with value: '$CURRENT_VALUE' — no change."
  exit 0
fi

echo "Tag '$TAG_KEY' is missing or empty — will set it."

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[Dry run] Would run:"
  echo "az resource tag --ids \"$RESOURCE_ID\" --is-incremental --tags \"$TAG_KEY=$TAG_VALUE\""
  exit 0
fi

# Merge a single tag without replacing others; avoids provider model validation
az resource tag --ids "$RESOURCE_ID" --is-incremental --tags "$TAG_KEY=$TAG_VALUE" >/dev/null

# Verify
NEW_JSON="$(az resource show --ids "$RESOURCE_ID" --query "tags.${TAG_KEY}" -o json || echo 'null')"
NEW_VALUE="${NEW_JSON%\"}"; NEW_VALUE="${NEW_VALUE#\"}"
if [[ "$NEW_VALUE" == "$TAG_VALUE" ]]; then
  echo "Success: tag '$TAG_KEY' set to '$TAG_VALUE'."
else
  echo "Warning: attempted to set tag, but verification read '$NEW_VALUE'." >&2
  exit 2
fi