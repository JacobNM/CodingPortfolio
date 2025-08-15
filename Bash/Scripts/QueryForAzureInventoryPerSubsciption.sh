DATE=$(date +%F)
ENVIRONMENTNAME="staging"
OUT="$HOME/Downloads/azure_${ENVIRONMENTNAME}_inventory_${DATE}.csv"
SUBSCRIPTION="ba69753e-54c1-480b-a940-6cee4521a7ad"

az account set --subscription "$SUBSCRIPTION"
az config set extension.use_dynamic_install=yes_without_prompt >/dev/null

az graph query \
  --subscriptions "$SUBSCRIPTION" \
  --first 1000 \
  -q 'Resources
      | project id, name, type, resourceGroup, subscriptionId, location, tags
      | order by type asc, name asc' \
  -o json \
| jq -r '
  ["id","name","type","resourceGroup","subscriptionId","location","tags_json"],
  (.data[] | [
    .id, .name, .type, .resourceGroup, .subscriptionId, .location,
    (.tags // {} | tojson)
  ]) | @csv
' > "$OUT"

echo "Wrote $OUT"