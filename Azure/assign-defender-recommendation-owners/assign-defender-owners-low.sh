#!/bin/bash
# =============================================================================
# assign-defender-owners-low.sh
#
# Assigns furqan@vantageanalytics.com as governance owner (1-year due date)
# to all 116 LOW risk Defender for Cloud recommendations using az CLI.
#
# Prerequisites:
#   az login
#
# Usage:
#   chmod +x assign-defender-owners-low.sh
#   ./assign-defender-owners-low.sh
# =============================================================================

OWNER="furqan@vantageanalytics.com"
DUE_DATE="2027-04-29T04:00:00Z"
API_VERSION="2025-05-04"

# All 116 LOW risk assessment IDs from your CSV
ASSESSMENT_IDS=(
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/2026-imageprep/providers/microsoft.compute/virtualmachines/campaign-central-runner/providers/microsoft.security/assessments/dc5357d0-3858-4d17-a1a3-072840bff5be"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/metabase-01/providers/microsoft.security/assessments/dc5357d0-3858-4d17-a1a3-072840bff5be"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/metabase-01/providers/microsoft.security/assessments/6c99f570-2ce7-46bc-8175-cde013df43bc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/2026-imageprep/providers/microsoft.compute/virtualmachines/campaign-central-runner/providers/microsoft.security/assessments/6c99f570-2ce7-46bc-8175-cde013df43bc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/2026-imageprep/providers/microsoft.compute/virtualmachines/campaign-central-runner/providers/microsoft.security/assessments/a40cc620-e72c-fdf4-c554-c6ca2cd705c0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/metabase-01/providers/microsoft.security/assessments/a40cc620-e72c-fdf4-c554-c6ca2cd705c0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/2026-imageprep/providers/microsoft.compute/virtualmachines/campaign-central-runner/providers/microsoft.security/assessments/90386950-71ca-4357-a12e-486d1679427c"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/metabase-01/providers/microsoft.security/assessments/90386950-71ca-4357-a12e-486d1679427c"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/2026-imageprep/providers/microsoft.compute/virtualmachines/campaign-central-runner/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/metabase-01/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-va-queue-02/providers/microsoft.security/assessments/dc5357d0-3858-4d17-a1a3-072840bff5be"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.compute/virtualmachines/prod-in-queue-02/providers/microsoft.security/assessments/dc5357d0-3858-4d17-a1a3-072840bff5be"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/prodscheduler-02/providers/microsoft.security/assessments/dc5357d0-3858-4d17-a1a3-072840bff5be"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.compute/virtualmachines/prod-sa-queue-02/providers/microsoft.security/assessments/dc5357d0-3858-4d17-a1a3-072840bff5be"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.compute/virtualmachines/prod-sa-queue-02/providers/microsoft.security/assessments/6c99f570-2ce7-46bc-8175-cde013df43bc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-va-queue-02/providers/microsoft.security/assessments/6c99f570-2ce7-46bc-8175-cde013df43bc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.compute/virtualmachines/prod-in-queue-02/providers/microsoft.security/assessments/6c99f570-2ce7-46bc-8175-cde013df43bc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/prodscheduler-02/providers/microsoft.security/assessments/6c99f570-2ce7-46bc-8175-cde013df43bc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/prodscheduler-02/providers/microsoft.security/assessments/9dbdb071-d643-0d14-1dab-ed87d890e5a1"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/prodscheduler-02/providers/microsoft.security/assessments/bcb554cc-d873-c3d1-2780-ccd7c0b5d5b1"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/prodscheduler-02/providers/microsoft.security/assessments/322b46b6-6f56-5c3f-0559-4698056f075e"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.compute/virtualmachines/prod-in-queue-02/providers/microsoft.security/assessments/a40cc620-e72c-fdf4-c554-c6ca2cd705c0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/prodscheduler-02/providers/microsoft.security/assessments/a40cc620-e72c-fdf4-c554-c6ca2cd705c0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.compute/virtualmachines/prod-sa-queue-02/providers/microsoft.security/assessments/a40cc620-e72c-fdf4-c554-c6ca2cd705c0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-va-queue-02/providers/microsoft.security/assessments/a40cc620-e72c-fdf4-c554-c6ca2cd705c0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/prodscheduler-02/providers/microsoft.security/assessments/90386950-71ca-4357-a12e-486d1679427c"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.compute/virtualmachines/prod-sa-queue-02/providers/microsoft.security/assessments/90386950-71ca-4357-a12e-486d1679427c"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.compute/virtualmachines/prod-in-queue-02/providers/microsoft.security/assessments/90386950-71ca-4357-a12e-486d1679427c"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-va-queue-02/providers/microsoft.security/assessments/90386950-71ca-4357-a12e-486d1679427c"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/prodscheduler-02/providers/microsoft.security/assessments/17618b1a-ed14-49bb-b37f-9f8ba967be8b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.compute/virtualmachinescalesets/prod-sa-app/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.compute/virtualmachines/prod-in-queue-02/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.compute/virtualmachines/prodscheduler-02/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-va-queue-02/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.compute/virtualmachinescalesets/prod-in-app/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.compute/virtualmachines/prod-sa-queue-02/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.documentdb/databaseaccounts/prod-ad-attribution-db/providers/microsoft.security/assessments/334a182c-7c2c-41bc-ae1e-55327891ab50"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.documentdb/databaseaccounts/retailer-products-prd/providers/microsoft.security/assessments/334a182c-7c2c-41bc-ae1e-55327891ab50"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.dbformysql/flexibleservers/prod-va-db-readreplica/providers/microsoft.security/assessments/02fb778d-fd6c-4770-81ca-abec3cf36634"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.dbformysql/flexibleservers/prod-va-db/providers/microsoft.security/assessments/02fb778d-fd6c-4770-81ca-abec3cf36634"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/dataexplorerprd/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.storage/storageaccounts/inbounddiag/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/proddbbackupstore/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/campaigncentralprd/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/prodqueuepollerv2/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.storage/storageaccounts/prodsnowflakedump/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.storage/storageaccounts/satellitediag/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/hdusbidsprd/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/vantageprodcdnstorage/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/prodadattributionreader/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/globaldiag372/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/ctcproductsprd/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/ctcproductsprd/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/proddbbackupstore/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.storage/storageaccounts/prodsnowflakedump/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.storage/storageaccounts/inbounddiag/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/vantageprodcdnstorage/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/hdusbidsprd/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/globaldiag372/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/prodadattributionreader/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/dataexplorerprd/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/campaigncentralprd/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.storage/storageaccounts/prodadattributionwriter/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/prodqueuepollerv2/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/prodproductsservice/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.storage/storageaccounts/satellitediag/providers/microsoft.security/assessments/ad4f3ff1-30eb-5042-16ed-27198f640b8d"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachinescalesets/prod-va-app/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-snowflake-jumpbox/providers/microsoft.security/assessments/f2f595ec-5dc6-68b4-82ef-b63563e9c610"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.network/virtualnetworks/vantagevnet1/providers/microsoft.security/assessments/e3de1cc0-f4dd-3b34-e496-8b5381ba2d70"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.network/virtualnetworks/prodonsiteadattributionvnet/providers/microsoft.security/assessments/e3de1cc0-f4dd-3b34-e496-8b5381ba2d70"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.dbforpostgresql/flexibleservers/prod-in-flex-db-02/providers/microsoft.security/assessments/5d19e32c-489d-407c-9549-15d9ea36a8e0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.dbforpostgresql/flexibleservers/prod-sa-flex-db-01/providers/microsoft.security/assessments/5d19e32c-489d-407c-9549-15d9ea36a8e0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.dbforpostgresql/flexibleservers/prod-in-flex-db-03/providers/microsoft.security/assessments/5d19e32c-489d-407c-9549-15d9ea36a8e0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.dbforpostgresql/flexibleservers/prod-in-flex-db-04/providers/microsoft.security/assessments/5d19e32c-489d-407c-9549-15d9ea36a8e0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.dbforpostgresql/flexibleservers/prod-in-flex-db-01/providers/microsoft.security/assessments/5d19e32c-489d-407c-9549-15d9ea36a8e0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.dbforpostgresql/flexibleservers/prod-in-flex-db-05/providers/microsoft.security/assessments/5d19e32c-489d-407c-9549-15d9ea36a8e0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prod-vantage-secrets/providers/microsoft.security/assessments/f6b59724-4a05-aa38-33e2-25f15eecf00b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagekeyvaultcne/providers/microsoft.security/assessments/f6b59724-4a05-aa38-33e2-25f15eecf00b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prod-terraform-key-vault/providers/microsoft.security/assessments/f6b59724-4a05-aa38-33e2-25f15eecf00b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagekeyvault/providers/microsoft.security/assessments/f6b59724-4a05-aa38-33e2-25f15eecf00b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagekeyvaultcne/providers/microsoft.security/assessments/88bbc99c-e5af-ddd7-6105-6150b2bfa519"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagekeyvault/providers/microsoft.security/assessments/88bbc99c-e5af-ddd7-6105-6150b2bfa519"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prod-vantage-secrets/providers/microsoft.security/assessments/88bbc99c-e5af-ddd7-6105-6150b2bfa519"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagesecretvault/providers/microsoft.security/assessments/88bbc99c-e5af-ddd7-6105-6150b2bfa519"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prod-terraform-key-vault/providers/microsoft.security/assessments/88bbc99c-e5af-ddd7-6105-6150b2bfa519"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/cert-based-access/providers/microsoft.compute/virtualmachines/centos-cert-auth/providers/microsoft.security/assessments/dc5357d0-3858-4d17-a1a3-072840bff5be"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-snowflake-jumpbox/providers/microsoft.security/assessments/dc5357d0-3858-4d17-a1a3-072840bff5be"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagesecretvault/providers/microsoft.security/assessments/52f7826a-ace7-3107-dd0d-4875853c1576"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagekeyvault/providers/microsoft.security/assessments/52f7826a-ace7-3107-dd0d-4875853c1576"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prod-terraform-key-vault/providers/microsoft.security/assessments/52f7826a-ace7-3107-dd0d-4875853c1576"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-snowflake-jumpbox/providers/microsoft.security/assessments/6c99f570-2ce7-46bc-8175-cde013df43bc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/cert-based-access/providers/microsoft.compute/virtualmachines/centos-cert-auth/providers/microsoft.security/assessments/6c99f570-2ce7-46bc-8175-cde013df43bc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagekeyvault/providers/microsoft.security/assessments/4ed62ae4-5072-f9e7-8d94-51c76c48159a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagesecretvault/providers/microsoft.security/assessments/4ed62ae4-5072-f9e7-8d94-51c76c48159a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagekeyvaultcne/providers/microsoft.security/assessments/4ed62ae4-5072-f9e7-8d94-51c76c48159a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prod-vantage-secrets/providers/microsoft.security/assessments/4ed62ae4-5072-f9e7-8d94-51c76c48159a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prod-terraform-key-vault/providers/microsoft.security/assessments/4ed62ae4-5072-f9e7-8d94-51c76c48159a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/cert-based-access/providers/microsoft.compute/virtualmachines/centos-cert-auth/providers/microsoft.security/assessments/a40cc620-e72c-fdf4-c554-c6ca2cd705c0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-snowflake-jumpbox/providers/microsoft.security/assessments/a40cc620-e72c-fdf4-c554-c6ca2cd705c0"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-snowflake-jumpbox/providers/microsoft.security/assessments/90386950-71ca-4357-a12e-486d1679427c"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.cache/redis/prod-in-redis-01/providers/microsoft.security/assessments/35b25be2-d08a-e340-45ed-f08a95d804fc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.cache/redis/prod-va-redis-01/providers/microsoft.security/assessments/35b25be2-d08a-e340-45ed-f08a95d804fc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.cache/redis/prod-sa-redis-01/providers/microsoft.security/assessments/35b25be2-d08a-e340-45ed-f08a95d804fc"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagekeyvault/providers/microsoft.security/assessments/55ed2823-a834-42bd-96ec-d3d5c97d9c6b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prodvantagesecretvault/providers/microsoft.security/assessments/55ed2823-a834-42bd-96ec-d3d5c97d9c6b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.keyvault/vaults/prod-terraform-key-vault/providers/microsoft.security/assessments/55ed2823-a834-42bd-96ec-d3d5c97d9c6b"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/prodqueuepollerv3/providers/microsoft.security/assessments/cdc78c07-02b0-4af0-1cb2-cb7c672a8b0a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.storage/storageaccounts/prodqueuepollerv3/providers/microsoft.security/assessments/3b363842-30f5-4056-980d-3a40fa5de8b3"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.network/virtualnetworkgateways/vantagevpn/providers/microsoft.security/assessments/f949db47-2ea9-417d-a56f-3bb477ad574f"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/cert-based-access/providers/microsoft.compute/virtualmachines/centos-cert-auth/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachinescalesets/prod-va-worker/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/inbound/providers/microsoft.compute/virtualmachinescalesets/prod-in-worker/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/vantage/providers/microsoft.compute/virtualmachines/prod-snowflake-jumpbox/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/satellite/providers/microsoft.compute/virtualmachinescalesets/prod-sa-worker/providers/microsoft.security/assessments/efbbd784-656d-473a-9863-ea7693bfcd2a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.network/virtualnetworks/prodonsiteadattributionvnet/providers/microsoft.security/assessments/f67fb4ed-d481-44d7-91e5-efadf504f74a"
  "/subscriptions/f643daaa-1b7c-4c74-b0c6-f90b0170d3b7/resourcegroups/global/providers/microsoft.network/virtualnetworks/vantagevnet1/providers/microsoft.security/assessments/f67fb4ed-d481-44d7-91e5-efadf504f74a"
)

# --------------------------------------------------------------------------- #

echo ""
echo "============================================================"
echo "  Defender for Cloud - Governance Assignment (LOW)"
echo "============================================================"
echo "  Owner   : $OWNER"
echo "  Due Date: $DUE_DATE  (1 year)"
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
COUNTER=0

for ASSESSMENT_ID in "${ASSESSMENT_IDS[@]}"; do
  ((COUNTER++))
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

  printf "  [%3d/116] ► [%-35s] " "$COUNTER" "$RESOURCE_NAME"

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