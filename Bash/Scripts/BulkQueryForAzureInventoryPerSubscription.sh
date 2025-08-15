#!/usr/bin/env bash
set -euo pipefail

# Function to display usage
usage() {
  cat <<'EOF'
Usage:
  BulkQueryForAzureInventoryPerSubscription.sh -s <subscriptionIdOrName> -e <environmentName>
  BulkQueryForAzureInventoryPerSubscription.sh --help

Options:
  -s, --subscription    Azure subscription ID or name (required)
  -e, --environment     Environment name for output file (required)
  -h, --help            Show this help message

Notes:
  - Outputs a CSV file to ~/Downloads with Azure resource inventory for the specified subscription.
  - Requires Azure CLI and jq to be installed.
  - The output file is named azure_<environment>_inventory_<date>.csv
    where <date> is in YYYY-MM-DD format.
  - The CSV includes columns: id, name, type, resourceGroup, subscriptionId, location, tags_json

Example usage:
  BulkQueryForAzureInventoryPerSubscription.sh -s my-subscription -e production
    # This would create a file like ~/Downloads/azure_production_inventory_2024-06-27.csv

EOF
}

SUBID=""
ENVIRONMENTNAME=""

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--subscription) SUBID="$2"; shift 2 ;;
    -e|--environment) ENVIRONMENTNAME="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

if [ -z "$SUBID" ] || [ -z "$ENVIRONMENTNAME" ]; then
  echo "Error: --subscription and --environment are required." >&2
  usage; exit 1
fi

command -v az >/dev/null 2>&1 || { echo "Error: Azure CLI 'az' not found."; exit 1; }

DATE=$(date +%F)
OUT="$HOME/Downloads/azure_${ENVIRONMENTNAME}_inventory_${DATE}.csv"
PAGE_SIZE=1000
SKIP=0
WROTE_HEADER=0

echo "Using subscription: $SUBID"
az account set --subscription "$SUBID"
az config set extension.use_dynamic_install=yes_without_prompt >/dev/null

# Header
echo '"id","name","type","resourceGroup","subscriptionId","location","tags_json"' > "$OUT"

while : ; do
  RES=$(az graph query \
  --subscriptions "$SUBID" \
  --first $PAGE_SIZE \
  --skip $SKIP \
  -q 'Resources
    | project id, name, type, resourceGroup, subscriptionId, location, tags
    | order by id asc' \
  -o json)

  COUNT=$(jq '.count' <<<"$RES")
  [ "$COUNT" -eq 0 ] && break

  jq -r '
  .data[] | [
    .id, .name, .type, .resourceGroup, .subscriptionId, .location,
    (.tags // {} | tojson)
  ] | @csv
  ' <<<"$RES" >> "$OUT"

  SKIP=$((SKIP + PAGE_SIZE))
done

echo "Wrote $OUT"