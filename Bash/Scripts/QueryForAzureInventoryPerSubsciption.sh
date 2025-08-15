DATE=$(date +%F)
OUT="$HOME/Downloads/azure_production_inventory_${DATE}.csv"
SUBSCRIPTION="<subscription_id>"

# Make sure you're on the right subscription
az account set --subscription "$SUBSCRIPTION"

# (Optional) let Azure CLI install the Resource Graph extension if needed
az config set extension.use_dynamic_install=yes_without_prompt >/dev/null

az graph query \
  --subscriptions "$SUBSCRIPTION" \
  -q 'Resources
      | project id, name, type, resourceGroup, subscriptionId, location, tags
      | order by type asc, name asc' \
  -o json \
| jq -r '
  ["id","name","type","resourceGroup","subscriptionId","location","tags_json"],
  (.data[] | [
    .id,
    .name,
    .type,
    .resourceGroup,
    .subscriptionId,
    .location,
    (.tags // {} | tojson)
  ]) | @csv
' > "$OUT"

echo "Wrote $OUT"