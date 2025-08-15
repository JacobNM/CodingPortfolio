#!/usr/bin/env bash
set -euo pipefail

SUBID="<your-subscription-id>"
DATE=$(date +%F)
ENVIRONMENTNAME="<your-environment-name>" # e.g., "Production", "Staging", etc.
OUT="$HOME/Downloads/azure_${ENVIRONMENTNAME}_inventory_${DATE}.csv"
PAGE_SIZE=1000
SKIP=0
WROTE_HEADER=0

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