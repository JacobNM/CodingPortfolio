#!/usr/bin/env python3
import requests
import json
import sys

# Azure metadata constants
METADATA_URL = "http://169.254.169.254/metadata/identity/oauth2/token"
RESOURCE = "https://management.azure.com/"

# === CONFIG: EDIT THESE ===
SUBSCRIPTION_ID = "<YOUR_SUBSCRIPTION_ID>"
RESOURCE_GROUP = "Global"
VM_NAME = "ProdScheduler-02"
SRE_Prod_Alert_Slack = "<Slack_Webhook_URL>"

# Command to run on the VM (runs as root already)
COMMAND_TO_RUN = "supervisorctl status celerybeat-vantage"
# COMMAND_TO_RUN = "supervisorctl restart celerybeat-vantage"

def get_managed_identity_token():
    """Get an access token for the Azure management API using the Automation Account's system-assigned managed identity."""
    params = {
        "api-version": "2018-02-01",
        "resource": RESOURCE
    }
    headers = {
        "Metadata": "true"
    }

    response = requests.get(METADATA_URL, params=params, headers=headers)
    if response.status_code != 200:
        raise Exception(f"Failed to obtain managed identity token: {response.status_code} {response.text}")

    return response.json()["access_token"]

def invoke_run_command(access_token):
    """Invoke Run Command on a VM to execute the desired shell command."""
    url = (
        f"https://management.azure.com/subscriptions/{SUBSCRIPTION_ID}"
        f"/resourceGroups/{RESOURCE_GROUP}/providers/Microsoft.compute/virtualMachines/{VM_NAME}"
        f"/runCommand?api-version=2023-03-01"
    )

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }

    body = {
        "commandId": "RunShellScript",
        "script": [
            COMMAND_TO_RUN
        ]
    }

    print(f"Invoking Run Command on VM '{VM_NAME}' in resource group '{RESOURCE_GROUP}'...")
    response = requests.post(url, headers=headers, data=json.dumps(body))

    if response.status_code not in (200, 201, 202):
        raise Exception(f"Run Command invoke failed: {response.status_code} {response.text}")

    return response.json()

def print_run_command_output(result):
    """Pretty-print the Run Command result from Azure."""
    print("Run Command result (raw):")
    print(json.dumps(result, indent=2))

    # Try to extract common message formats
    try:
        value = result.get("value", [])
        for item in value:
            message = item.get("message")
            if message:
                print("----- MESSAGE -----")
                print(message)
    except Exception:
        pass

def main():
    try:
        token = get_managed_identity_token()
        result = invoke_run_command(token)
        print_run_command_output(result)
        print("Completed Run Command on celerybeat-vantage.")
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()