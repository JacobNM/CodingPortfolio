#!/bin/bash
# =============================================================================
# assign-defender-owners.sh
#
# Assigns furqan@vantageanalytics.com as governance owner (60-day due date)
# to all 22 HIGH risk Defender for Cloud recommendations using az CLI.
#
# Prerequisites:
#   brew install azure-cli   (if not already installed)
#   az login
#
# Usage:
#   chmod +x assign-defender-owners.sh
#   ./assign-defender-owners.sh
# =============================================================================

OWNER="furqan@vantageanalytics.com"
DUE_DATE="2026-06-28T04:00:00Z"
API_VERSION="2025-05-04"

# All 22 HIGH risk assessment IDs from your CSV
ASSESSMENT_IDS=(
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/metabase-01/providers/microsoft.security/assessments/1195afff-c881-495e-9bc5-1486211ae03f"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/2026-imageprep/providers/microsoft.compute/virtualmachines/campaign-central-runner/providers/microsoft.security/assessments/f2f595ec-5dc6-68b4-82ef-b63563e9c610"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/2026-imageprep/providers/microsoft.compute/virtualmachines/campaign-central-runner/providers/microsoft.security/assessments/1195afff-c881-495e-9bc5-1486211ae03f"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/prodscheduler-02/providers/microsoft.security/assessments/1195afff-c881-495e-9bc5-1486211ae03f"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-va-queue-02/providers/microsoft.security/assessments/1195afff-c881-495e-9bc5-1486211ae03f"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.compute/virtualmachines/prod-in-queue-02/providers/microsoft.security/assessments/1195afff-c881-495e-9bc5-1486211ae03f"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.compute/virtualmachines/prod-sa-queue-02/providers/microsoft.security/assessments/1195afff-c881-495e-9bc5-1486211ae03f"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.documentdb/databaseaccounts/prod-ad-attribution-db/providers/microsoft.security/assessments/14acab4e-ad95-11ec-b909-0242ac120002"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/globaldiag372/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/prodadattributionreader/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/campaigncentralprd/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/dataexplorerprd/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/ctcproductsprd/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/prodproductsservice/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/proddbbackupstore/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/prodqueuepollerv2/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.storage/storageaccounts/prodsnowflakedump/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/hdusbidsprd/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.storage/storageaccounts/satellitediag/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/vantageprodcdnstorage/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/prodadattributionwriter/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.storage/storageaccounts/inbounddiag/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
)

# --------------------------------------------------------------------------- #

echo ""
echo "============================================================"
echo "  Defender for Cloud - Governance Assignment"
echo "============================================================"
echo "  Owner   : $OWNER"
echo "  Due Date: $DUE_DATE"
echo "  Total   : ${#ASSESSMENT_IDS[@]} recommendations"
echo "============================================================"
echo ""

# Verify az login
ACCOUNT=$(az account show --query "user.name" -o tsv 2>/dev/null)
if [ -z "$ACCOUNT" ]; then
  echo "✘ Not logged in. Run: az login"
  exit 1
fi
SUB=$(az account show --query "name" -o tsv)
echo "✔ Logged in as: $ACCOUNT"
echo "✔ Subscription: $SUB"
echo ""

SUCCESS=0
FAIL=0

for ASSESSMENT_ID in "${ASSESSMENT_IDS[@]}"; do
  # Extract a short resource name from the ID for display
  RESOURCE_NAME=$(echo "$ASSESSMENT_ID" | awk -F'/' '{print $9}')

  # Each assignment needs a unique name — use a fresh UUID
  ASSIGNMENT_NAME=$(uuidgen | tr '[:upper:]' '[:lower:]')

  URL="https://management.azure.com${ASSESSMENT_ID}/governanceAssignments/${ASSIGNMENT_NAME}?api-version=${API_VERSION}"

  BODY=$(cat <<EOF
{
  "properties": {
    "owner": "$OWNER",
    "remediationDueDate": "$DUE_DATE",
    "isGracePeriod": false,
    "governanceEmailNotification": {
      "disableManagerEmailNotification": false,
      "disableOwnerEmailNotification": false
    }
  }
}
EOF
)

  printf "  ► [%-35s] " "$RESOURCE_NAME"

  RESPONSE=$(az rest --method PUT --url "$URL" --body "$BODY" --headers "Content-Type=application/json" 2>&1)

  if [ $? -eq 0 ]; then
    echo "✔ SUCCESS"
    ((SUCCESS++))
  else
    ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | head -1 | sed 's/"message":"//;s/"//')
    echo "✘ FAILED: ${ERROR_MSG:-$RESPONSE}"
    ((FAIL++))
  fi
done

echo ""
echo "============================================================"
echo "  Summary"
echo "============================================================"
echo "  ✔ Succeeded : $SUCCESS"
echo "  ✘ Failed    : $FAIL"
echo "============================================================"