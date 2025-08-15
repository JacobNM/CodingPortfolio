DATE=$(date +%F)
ENVIRONMENTNAME="release"
OUT="$HOME/Downloads/azure_${ENVIRONMENTNAME}_inventory_${DATE}.csv"
SUBSCRIPTIONID="2d239316-7ee9-4456-aa90-03a9ee0aa3ed"

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