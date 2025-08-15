DATE=$(date +%F)
ENVIRONMENTNAME="<your-environment-name>"  # e.g. "prod", "dev", "test"
OUT="$HOME/Downloads/azure_${ENVIRONMENTNAME}_inventory_${DATE}.csv"
SUBSCRIPTIONID="<your-subscription-id>"

az account set --subscription "$SUBSCRIPTIONID"
az config set extension.use_dynamic_install=yes_without_prompt >/dev/null

az graph query \
  --subscriptions "$SUBSCRIPTIONID" \
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