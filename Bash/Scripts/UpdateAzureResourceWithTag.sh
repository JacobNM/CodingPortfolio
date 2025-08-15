#!/usr/bin/env bash
# add-missing-tag.sh
# Check an Azure resource for a tag; if missing/empty, add it.
# Requires: Azure CLI (`az`) logged in with permissions to read/update the resource.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  # Option A: Provide a full resource ID
  UpdateAzureResourceWithTag.sh -i <resourceId> -k <tagKey> -v <tagValue> [--dry-run]

  # Option B: Provide name, group, and type
  UpdateAzureResourceWithTag.sh -g <resourceGroup> -n <name> -t <resourceType> -k <tagKey> -v <tagValue> [--dry-run]

Notes:
  - <resourceType> is the full type, e.g. "Microsoft.Compute/virtualMachines"
  - The script preserves existing tags and only sets the specified key if it is missing or empty.
  - Use --dry-run to see what would happen without making changes.
EOF
}

# Defaults
RESOURCE_ID=""
RG=""
NAME=""
TYPE=""
TAG_KEY=""
TAG_VALUE=""
DRY_RUN=0

# Parse args
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

# Validate inputs
if [[ -z "$TAG_KEY" || -z "$TAG_VALUE" ]]; then
  echo "Error: tag key and value are required." >&2
  usage; exit 1
fi

if [[ -z "$RESOURCE_ID" ]]; then
  if [[ -z "$RG" || -z "$NAME" || -z "$TYPE" ]]; then
    echo "Error: either --id or (--resource-group, --name, --type) must be provided." >&2
    usage; exit 1
  fi
fi

# Confirm az is available
if ! command -v az >/dev/null 2>&1; then
  echo "Error: Azure CLI 'az' is not installed or not in PATH." >&2
  exit 1
fi

# Resolve resource ID if needed
if [[ -z "$RESOURCE_ID" ]]; then
  # shellcheck disable=SC2207
  RESOURCE_ID="$(az resource show \
    --resource-group "$RG" \
    --name "$NAME" \
    --resource-type "$TYPE" \
    --query id -o tsv)"
  if [[ -z "$RESOURCE_ID" ]]; then
    echo "Error: failed to resolve resource ID." >&2
    exit 1
  fi
fi

echo "Target resource: $RESOURCE_ID"
echo "Ensuring tag: $TAG_KEY=$TAG_VALUE"

# Read current tag value (empty string if not set)
CURRENT_VALUE="$(az resource show --ids "$RESOURCE_ID" --query "tags['$TAG_KEY']" -o tsv || true)"

if [[ -n "$CURRENT_VALUE" ]]; then
  echo "Tag '$TAG_KEY' already present with value: '$CURRENT_VALUE' — no change."
  exit 0
fi

echo "Tag '$TAG_KEY' is missing or empty — will set it."

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[Dry run] Would run:"
  echo "az resource update --ids \"$RESOURCE_ID\" --set \"tags.$TAG_KEY=$TAG_VALUE\""
  exit 0
fi

# Update only the single tag key (preserves other tags)
az resource update --ids "$RESOURCE_ID" --set "tags.$TAG_KEY=$TAG_VALUE" >/dev/null

# Verify
NEW_VALUE="$(az resource show --ids "$RESOURCE_ID" --query "tags['$TAG_KEY']" -o tsv || true)"
if [[ "$NEW_VALUE" == "$TAG_VALUE" ]]; then
  echo "Success: tag '$TAG_KEY' set to '$TAG_VALUE'."
else
  echo "Warning: attempted to set tag, but verification read '$NEW_VALUE'." >&2
  exit 2
fi