#!/usr/bin/env bash
set -euo pipefail

# Copy managed VM images whose name contains "2026" from one RG to another.
# Requirements: Azure CLI (az) logged in, and permissions to read/write images in both RGs.

SRC_RG="${1:-}"
DST_RG="${2:-}"
SUBSCRIPTION_ID="${3:-}"   # optional; if empty, uses current az context
NAME_CONTAINS="${4:-2026}" # optional; default "2026"

if [[ -z "$SRC_RG" || -z "$DST_RG" ]]; then
  echo "Usage: $0 <source_rg> <dest_rg> [subscription_id] [name_contains]"
  echo "Example: $0 2025-ImagePrep 2026-ImagePrep <sub-id> 2026"
  exit 1
fi

# Ensure logged in
az account show >/dev/null 2>&1 || {
  echo "Not logged into Azure CLI. Run: az login"
  exit 1
}

# Optionally set subscription
if [[ -n "$SUBSCRIPTION_ID" ]]; then
  az account set --subscription "$SUBSCRIPTION_ID"
fi

# Verify RGs exist
az group show -n "$SRC_RG" >/dev/null
az group show -n "$DST_RG" >/dev/null

echo "Listing images in '$SRC_RG' containing '$NAME_CONTAINS'..."
mapfile -t IMAGES < <(
  az image list -g "$SRC_RG" \
    --query "[?contains(name, '${NAME_CONTAINS}')].name" -o tsv
)

if [[ "${#IMAGES[@]}" -eq 0 ]]; then
  echo "No managed images found in '$SRC_RG' containing '$NAME_CONTAINS'."
  exit 0
fi

echo "Found ${#IMAGES[@]} image(s):"
printf ' - %s\n' "${IMAGES[@]}"

for IMG in "${IMAGES[@]}"; do
  SRC_ID="$(az image show -g "$SRC_RG" -n "$IMG" --query id -o tsv)"
  LOC="$(az image show -g "$SRC_RG" -n "$IMG" --query location -o tsv)"

  # Destination name: keep same name by default.
  # If you want to avoid collisions, change DST_NAME to "${IMG}-copy" or include a suffix.
  DST_NAME="$IMG"

  echo
  echo "==> Copying '$IMG' -> '$DST_RG/$DST_NAME' (location: $LOC)"

  # Skip if destination image already exists
  if az image show -g "$DST_RG" -n "$DST_NAME" >/dev/null 2>&1; then
    echo "    Destination image already exists; skipping: $DST_RG/$DST_NAME"
    continue
  fi

  az image create \
    -g "$DST_RG" \
    -n "$DST_NAME" \
    -l "$LOC" \
    --source "$SRC_ID" \
    --only-show-errors >/dev/null

  echo "    Done."
done

echo
echo "All matching images processed."