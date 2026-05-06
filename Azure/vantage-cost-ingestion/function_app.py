import azure.functions as func
import logging
import os
import gzip
import csv
import json
import io
from datetime import datetime, timezone
from typing import Any

from azure.identity import ManagedIdentityCredential
from azure.monitor.ingestion import LogsIngestionClient
from azure.storage.blob import BlobServiceClient
from azure.core.exceptions import HttpResponseError

app = func.FunctionApp()

# ---------------------------------------------------------------------------
# Column mapping: CSV camelCase → table PascalCase
# ---------------------------------------------------------------------------
COLUMN_MAP = {
    "invoiceId": "InvoiceId",
    "previousInvoiceId": "PreviousInvoiceId",
    "billingAccountId": "BillingAccountId",
    "billingAccountName": "BillingAccountName",
    "billingProfileId": "BillingProfileId",
    "billingProfileName": "BillingProfileName",
    "invoiceSectionId": "InvoiceSectionId",
    "invoiceSectionName": "InvoiceSectionName",
    "resellerName": "ResellerName",
    "resellerMpnId": "ResellerMpnId",
    "costCenter": "CostCenter",
    "billingPeriodEndDate": "BillingPeriodEndDate",
    "billingPeriodStartDate": "BillingPeriodStartDate",
    "servicePeriodEndDate": "ServicePeriodEndDate",
    "servicePeriodStartDate": "ServicePeriodStartDate",
    "date": "Date",
    "serviceFamily": "ServiceFamily",
    "productOrderId": "ProductOrderId",
    "productOrderName": "ProductOrderName",
    "consumedService": "ConsumedService",
    "meterId": "MeterId",
    "meterName": "MeterName",
    "meterCategory": "MeterCategory",
    "meterSubCategory": "MeterSubCategory",
    "meterRegion": "MeterRegion",
    "ProductId": "ProductId",
    "ProductName": "ProductName",
    "SubscriptionId": "SubscriptionId",
    "subscriptionName": "SubscriptionName",
    "publisherType": "PublisherType",
    "publisherId": "PublisherId",
    "publisherName": "PublisherName",
    "resourceGroupName": "ResourceGroupName",
    "ResourceId": "ResourceId",
    "resourceLocation": "ResourceLocation",
    "location": "Location",
    "effectivePrice": "EffectivePrice",
    "quantity": "Quantity",
    "unitOfMeasure": "UnitOfMeasure",
    "chargeType": "ChargeType",
    "billingCurrency": "BillingCurrency",
    "pricingCurrency": "PricingCurrency",
    "costInBillingCurrency": "CostInBillingCurrency",
    "costInPricingCurrency": "CostInPricingCurrency",
    "costInUsd": "CostInUsd",
    "paygCostInBillingCurrency": "PaygCostInBillingCurrency",
    "paygCostInUsd": "PaygCostInUsd",
    "exchangeRatePricingToBilling": "ExchangeRatePricingToBilling",
    "exchangeRateDate": "ExchangeRateDate",
    "isAzureCreditEligible": "IsAzureCreditEligible",
    "serviceInfo1": "ServiceInfo1",
    "serviceInfo2": "ServiceInfo2",
    "additionalInfo": "AdditionalInfo",
    "tags": "Tags",
    "PayGPrice": "PayGPrice",
    "frequency": "Frequency",
    "term": "Term",
    "reservationId": "ReservationId",
    "reservationName": "ReservationName",
    "pricingModel": "PricingModel",
    "unitPrice": "UnitPrice",
    "costAllocationRuleName": "CostAllocationRuleName",
    "benefitId": "BenefitId",
    "benefitName": "BenefitName",
    "provider": "Provider",
}

DYNAMIC_FIELDS = {"Tags", "AdditionalInfo"}
REAL_FIELDS = {
    "EffectivePrice", "Quantity", "UnitPrice", "CostInBillingCurrency",
    "CostInPricingCurrency", "CostInUsd", "PaygCostInBillingCurrency",
    "PaygCostInUsd", "ExchangeRatePricingToBilling", "PayGPrice",
}
BOOL_FIELDS = {"IsAzureCreditEligible"}

# Environment variables (set in Function App configuration)
STORAGE_ACCOUNT_URL = os.environ["STORAGE_ACCOUNT_URL"]
DCE_ENDPOINT = os.environ["DCE_ENDPOINT"]
DCR_IMMUTABLE_ID = os.environ["DCR_IMMUTABLE_ID"]
STREAM_NAME = "Custom-AzureCostData_CL"
TRACKING_CONTAINER = "cost-ingestion-tracking"
BATCH_SIZE = 500


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def extract_environment(blob_path: str) -> str:
    """
    Derive environment name from the blob path.
    Path format: raw/{env}-actual-cost/{billing-period}/{timestamp}/{guid}/part_*.csv.gz
    Example:     raw/prod-actual-cost/20260101-20260131/20260101T120000/abc123/part_0_0001.csv.gz
                 → "prod"
    """
    try:
        folder = blob_path.split("/")[1]       # e.g. "prod-actual-cost"
        return folder.replace("-actual-cost", "")
    except (IndexError, AttributeError):
        logging.warning(f"Could not extract environment from path: {blob_path}")
        return "unknown"


def parse_value(value: str, field_name: str) -> Any:
    """Cast a raw CSV string to the correct Python type for its field."""
    if value == "" or value is None:
        return {} if field_name in DYNAMIC_FIELDS else None

    if field_name in DYNAMIC_FIELDS:
        try:
            return json.loads(value)
        except (json.JSONDecodeError, TypeError):
            return {}

    if field_name in REAL_FIELDS:
        try:
            return float(value)
        except (ValueError, TypeError):
            return None

    if field_name in BOOL_FIELDS:
        return value.strip().lower() in ("true", "1", "yes")

    return value


def transform_row(row: dict, environment: str) -> dict:
    """Map a CSV row (camelCase keys) to our PascalCase schema, injecting Environment."""
    record = {
        pascal_col: parse_value(row.get(csv_col, ""), pascal_col)
        for csv_col, pascal_col in COLUMN_MAP.items()
    }
    record["Environment"] = environment
    # TimeGenerated must be set — prefer the export Date, fall back to now
    record["TimeGenerated"] = record.get("Date") or datetime.now(timezone.utc).isoformat()
    return record


def is_already_processed(blob_service_client: BlobServiceClient, blob_path: str) -> bool:
    """Return True if a processing marker exists for this blob (idempotency check)."""
    marker = blob_path.replace("/", "_") + ".processed"
    try:
        client = blob_service_client.get_container_client(TRACKING_CONTAINER)
        client.get_blob_client(marker).get_blob_properties()
        return True
    except Exception:
        return False


def mark_as_processed(blob_service_client: BlobServiceClient, blob_path: str) -> None:
    """Write a processing marker so this blob is skipped on any retry."""
    marker = blob_path.replace("/", "_") + ".processed"
    try:
        container_client = blob_service_client.get_container_client(TRACKING_CONTAINER)
        try:
            container_client.create_container()
        except Exception:
            pass  # Already exists — safe to ignore
        container_client.get_blob_client(marker).upload_blob(
            datetime.now(timezone.utc).isoformat(),
            overwrite=True,
        )
    except Exception as e:
        # Non-fatal: log and continue — worst case we re-process on next trigger
        logging.warning(f"Failed to write processing marker for {blob_path}: {e}")


# ---------------------------------------------------------------------------
# Function entry point
# ---------------------------------------------------------------------------

@app.event_grid_trigger(arg_name="event")
def ingest_cost_export(event: func.EventGridEvent) -> None:
    """
    Triggered by Event Grid when a new blob is created in the cost-exports container.

    Pipeline:
      1. Extract blob path + environment from the event
      2. Idempotency check — skip if already processed
      3. Download and decompress the .csv.gz file
      4. Parse CSV rows, map columns, inject Environment
      5. POST records in batches to the DCE → DCR → AzureCostData_CL
      6. Write processing marker
    """
    event_data = event.get_json()
    blob_url = event_data.get("url", "")

    # Derive the container-relative blob path from the full blob URL
    # URL format: https://{account}.blob.core.windows.net/cost-exports/{blob_path}
    try:
        blob_path = blob_url.split("/cost-exports/", 1)[1]
    except IndexError:
        logging.error(f"Unexpected blob URL format, cannot parse path: {blob_url}")
        return

    logging.info(f"Event received for blob: {blob_path}")

    if not blob_path.endswith(".csv.gz"):
        logging.info(f"Skipping non-csv.gz blob: {blob_path}")
        return

    credential = ManagedIdentityCredential()
    blob_service_client = BlobServiceClient(
        account_url=STORAGE_ACCOUNT_URL,
        credential=credential,
    )

    # --- Idempotency ---
    if is_already_processed(blob_service_client, blob_path):
        logging.info(f"Already processed, skipping: {blob_path}")
        return

    environment = extract_environment(blob_path)
    logging.info(f"Detected environment: {environment}")

    # --- Download ---
    try:
        blob_client = blob_service_client \
            .get_container_client("cost-exports") \
            .get_blob_client(blob_path)
        compressed_data = blob_client.download_blob().readall()
        logging.info(f"Downloaded {len(compressed_data):,} compressed bytes")
    except Exception as e:
        logging.error(f"Failed to download blob {blob_path}: {e}")
        raise

    # --- Decompress ---
    try:
        decompressed = gzip.decompress(compressed_data)
        logging.info(f"Decompressed to {len(decompressed):,} bytes")
    except Exception as e:
        logging.error(f"Failed to decompress {blob_path}: {e}")
        raise

    # --- Parse + transform ---
    try:
        # utf-8-sig strips the BOM that Excel/Azure sometimes writes
        text = decompressed.decode("utf-8-sig")
        reader = csv.DictReader(io.StringIO(text))
        records = [transform_row(row, environment) for row in reader]
    except Exception as e:
        logging.error(f"Failed to parse CSV from {blob_path}: {e}")
        raise

    logging.info(f"Parsed {len(records):,} records from {blob_path}")

    if not records:
        logging.warning(f"No records in {blob_path} — marking processed and exiting")
        mark_as_processed(blob_service_client, blob_path)
        return

    # --- Ingest via Logs Ingestion API ---
    ingestion_client = LogsIngestionClient(
        endpoint=DCE_ENDPOINT,
        credential=credential,
    )

    total_ingested = 0
    for i in range(0, len(records), BATCH_SIZE):
        batch = records[i : i + BATCH_SIZE]
        try:
            ingestion_client.upload(
                rule_id=DCR_IMMUTABLE_ID,
                stream_name=STREAM_NAME,
                logs=batch,
            )
            total_ingested += len(batch)
            logging.info(
                f"Batch {i // BATCH_SIZE + 1} ingested: "
                f"{len(batch)} records (total so far: {total_ingested})"
            )
        except HttpResponseError as e:
            logging.error(
                f"Ingestion API error on batch starting at row {i}: "
                f"status={e.status_code} message={e.message}"
            )
            raise

    logging.info(f"Ingestion complete: {total_ingested:,} records from {blob_path}")
    mark_as_processed(blob_service_client, blob_path)