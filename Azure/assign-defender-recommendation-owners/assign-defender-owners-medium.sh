#!/bin/bash
# =============================================================================
# assign-defender-owners-medium.sh
#
# Assigns furqan@vantageanalytics.com as governance owner (90-day due date)
# to all 11 MEDIUM risk Defender for Cloud recommendations using az CLI.
#
# Prerequisites:
#   az login
#
# Usage:
#   chmod +x assign-defender-owners-medium.sh
#   ./assign-defender-owners-medium.sh
# =============================================================================

OWNER="furqan@vantageanalytics.com"
DUE_DATE="2026-07-28T04:00:00Z"
API_VERSION="2025-05-04"

# All 11 MEDIUM risk assessment IDs from your CSV
ASSESSMENT_IDS=(
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/2026-imageprep/providers/microsoft.compute/virtualmachines/campaign-central-runner/providers/microsoft.security/assessments/9dbdb071-d643-0d14-1dab-ed87d890e5a1"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/2026-imageprep/providers/microsoft.compute/virtualmachines/campaign-central-runner/providers/microsoft.security/assessments/bcb554cc-d873-c3d1-2780-ccd7c0b5d5b1"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/metabase-01/providers/microsoft.security/assessments/322b46b6-6f56-5c3f-0559-4698056f075e"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/metabase-01/providers/microsoft.security/assessments/17618b1a-ed14-49bb-b37f-9f8ba967be8b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/2026-imageprep/providers/microsoft.compute/virtualmachines/campaign-central-runner/providers/microsoft.security/assessments/17618b1a-ed14-49bb-b37f-9f8ba967be8b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.compute/virtualmachines/prod-sa-queue-02/providers/microsoft.security/assessments/322b46b6-6f56-5c3f-0559-4698056f075e"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-va-queue-02/providers/microsoft.security/assessments/322b46b6-6f56-5c3f-0559-4698056f075e"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.compute/virtualmachines/prod-in-queue-02/providers/microsoft.security/assessments/322b46b6-6f56-5c3f-0559-4698056f075e"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.compute/virtualmachines/prod-in-queue-02/providers/microsoft.security/assessments/17618b1a-ed14-49bb-b37f-9f8ba967be8b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.compute/virtualmachines/prod-sa-queue-02/providers/microsoft.security/assessments/17618b1a-ed14-49bb-b37f-9f8ba967be8b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-va-queue-02/providers/microsoft.security/assessments/17618b1a-ed14-49bb-b37f-9f8ba967be8b"
)

# --------------------------------------------------------------------------- #

echo ""
echo "============================================================"
echo "  Defender for Cloud - Governance Assignment (MEDIUM)"
echo "============================================================"
echo "  Owner   : $OWNER"
echo "  Due Date: $DUE_DATE  (90 days)"
echo "  Total   : ${#ASSESSMENT_IDS[@]} recommendations"
echo "============================================================"
echo ""

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
  RESOURCE_NAME=$(echo "$ASSESSMENT_ID" | awk -F'/' '{print $9}')
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