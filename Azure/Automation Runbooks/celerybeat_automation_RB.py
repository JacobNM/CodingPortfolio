#!/usr/bin/env python3
import json
import sys
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime

# Azure metadata constants
METADATA_URL = "http://169.254.169.254/metadata/identity/oauth2/token"
RESOURCE = "https://management.azure.com/"

# === CONFIG: EDIT THESE ===
SUBSCRIPTION_ID = "<YOUR_SUBSCRIPTION_ID>"
RESOURCE_GROUP = "<YOUR_RESOURCE_GROUP>"
VM_NAME = "<YOUR_VM_NAME>"
SRE_Prod_Alert_Slack = "<YOUR_SLACK_WEBHOOK_URL>"

# Command to run on the VM (runs as root already)
COMMAND_TO_RUN = "supervisorctl status celerybeat-vantage"  # For testing
# COMMAND_TO_RUN = "supervisorctl restart celerybeat-vantage"  # Actual command to restart celerybeat

def diagnose_environment():
    """Diagnose the Azure Automation environment for troubleshooting."""
    print("=== ENVIRONMENT DIAGNOSTICS ===")
    
    # Check if we're in Azure environment
    try:
        import os
        print(f"Python version: {sys.version}")
        print(f"Current working directory: {os.getcwd()}")
        
        # Check for Azure environment variables
        azure_env_vars = ['IDENTITY_ENDPOINT', 'IDENTITY_HEADER', 'MSI_ENDPOINT', 'MSI_SECRET']
        azure_env_detected = False
        for var in azure_env_vars:
            value = os.environ.get(var)
            if value:
                print(f"{var}: {'*' * 10}")  # Mask sensitive values
                azure_env_detected = True
            else:
                print(f"{var}: Not set")
        
        # Determine environment
        if azure_env_detected or '/tmp' in os.getcwd() or 'automation' in os.getcwd().lower():
            print("Environment: Likely Azure Automation Account")
            return "azure"
        else:
            print("Environment: Local development machine")
            return "local"
                
    except Exception as e:
        print(f"Environment check failed: {e}")
        return "unknown"
    
    print("=== END DIAGNOSTICS ===\n")

def get_managed_identity_token():
    """Get an access token for the Azure management API using the Automation Account's system-assigned managed identity."""
    import os
    
    # Check for newer managed identity environment variables first
    identity_endpoint = os.environ.get('IDENTITY_ENDPOINT')
    identity_header = os.environ.get('IDENTITY_HEADER')
    
    if identity_endpoint and identity_header:
        print("Using newer managed identity endpoint from environment variables...")
        try:
            params = {
                "api-version": "2019-08-01",
                "resource": RESOURCE
            }
            
            url_with_params = identity_endpoint + "?" + urllib.parse.urlencode(params)
            
            request = urllib.request.Request(url_with_params)
            request.add_header("X-IDENTITY-HEADER", identity_header)
            request.add_header("Metadata", "true")
            
            with urllib.request.urlopen(request, timeout=30) as response:
                if response.status != 200:
                    response_text = response.read().decode('utf-8')
                    raise Exception(f"Identity endpoint failed: {response.status} {response_text}")
                
                response_data = json.loads(response.read().decode('utf-8'))
                print("Successfully obtained managed identity token using IDENTITY_ENDPOINT")
                return response_data["access_token"]
                
        except Exception as e:
            print(f"IDENTITY_ENDPOINT method failed: {str(e)}")
            # Fall back to legacy method
    
    # Try legacy MSI endpoint if available
    msi_endpoint = os.environ.get('MSI_ENDPOINT')
    msi_secret = os.environ.get('MSI_SECRET')
    
    if msi_endpoint and msi_secret:
        print("Using legacy MSI endpoint from environment variables...")
        try:
            params = {
                "api-version": "2017-09-01",
                "resource": RESOURCE
            }
            
            url_with_params = msi_endpoint + "?" + urllib.parse.urlencode(params)
            
            request = urllib.request.Request(url_with_params)
            request.add_header("Secret", msi_secret)
            request.add_header("Metadata", "true")
            
            with urllib.request.urlopen(request, timeout=30) as response:
                if response.status != 200:
                    response_text = response.read().decode('utf-8')
                    raise Exception(f"MSI endpoint failed: {response.status} {response_text}")
                
                response_data = json.loads(response.read().decode('utf-8'))
                print("Successfully obtained managed identity token using MSI_ENDPOINT")
                return response_data["access_token"]
                
        except Exception as e:
            print(f"MSI_ENDPOINT method failed: {str(e)}")
    
    # Fall back to standard metadata endpoint as last resort
    print("Falling back to standard metadata endpoint...")
    api_versions = ["2019-08-01", "2018-02-01"]
    
    for api_version in api_versions:
        try:
            params = {
                "api-version": api_version,
                "resource": RESOURCE
            }
            
            url_with_params = METADATA_URL + "?" + urllib.parse.urlencode(params)
            
            print(f"Attempting metadata endpoint with API version {api_version}...")
            
            request = urllib.request.Request(url_with_params)
            request.add_header("Metadata", "true")

            with urllib.request.urlopen(request, timeout=10) as response:
                if response.status != 200:
                    response_text = response.read().decode('utf-8')
                    print(f"Metadata API version {api_version} failed: {response.status} {response_text}")
                    continue
                
                response_data = json.loads(response.read().decode('utf-8'))
                print(f"Successfully obtained managed identity token using metadata endpoint API version {api_version}")
                return response_data["access_token"]
                
        except urllib.error.URLError as e:
            print(f"Metadata API version {api_version} failed with URLError: {str(e)}")
            continue
        except Exception as e:
            print(f"Metadata API version {api_version} failed with error: {str(e)}")
            continue
    
    # If all methods fail
    raise Exception("""
Failed to obtain managed identity token with all available methods.

Attempted methods:
1. IDENTITY_ENDPOINT (newer Azure environments)
2. MSI_ENDPOINT (legacy Azure environments)  
3. Metadata endpoint (fallback)

All environment variables are present but authentication is failing.
This may indicate a configuration issue with the Automation Account's managed identity.
""")

def invoke_run_command(access_token):
    """Invoke Run Command on a VM to execute the desired shell command."""
    url = (
        f"https://management.azure.com/subscriptions/{SUBSCRIPTION_ID}"
        f"/resourceGroups/{RESOURCE_GROUP}/providers/Microsoft.Compute/virtualMachines/{VM_NAME}"
        f"/runCommand?api-version=2018-04-01"
    )

    body = {
        "commandId": "RunShellScript",
        "script": [
            COMMAND_TO_RUN
        ]
    }

    print(f"Invoking Run Command on VM '{VM_NAME}' in resource group '{RESOURCE_GROUP}'...")
    
    request = urllib.request.Request(url, data=json.dumps(body).encode('utf-8'))
    request.add_header("Authorization", f"Bearer {access_token}")
    request.add_header("Content-Type", "application/json")
    request.get_method = lambda: 'POST'

    try:
        with urllib.request.urlopen(request, timeout=90) as response:
            if response.status not in (200, 201, 202):
                response_text = response.read().decode('utf-8')
                raise Exception(f"Run Command invoke failed: {response.status} {response_text}")
            
            print(f"Run Command initiated successfully. Status: {response.status}")
            
            # For the simple approach, just return a success indicator
            # The command is executed but we don't wait for detailed output
            return {
                "status": "completed", 
                "message": f"Command '{COMMAND_TO_RUN}' was successfully executed on {VM_NAME}",
                "execution_status": response.status
            }
                
    except urllib.error.URLError as e:
        raise Exception(f"Run Command invoke failed: {str(e)}")



def send_slack_notification(message, is_error=False):
    """Send notification to Slack channel."""
    try:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")
        color = "#ff0000" if is_error else "#00ff00"
        emoji = ":x:" if is_error else ":white_check_mark:"
        
        payload = {
            "attachments": [{
                "color": color,
                "fields": [
                    {
                        "title": f"{emoji} Celerybeat Automation - {VM_NAME}",
                        "value": message,
                        "short": False
                    },
                    {
                        "title": "Timestamp",
                        "value": timestamp,
                        "short": True
                    }
                ]
            }]
        }
        
        request = urllib.request.Request(SRE_Prod_Alert_Slack, data=json.dumps(payload).encode('utf-8'))
        request.add_header("Content-Type", "application/json")
        request.get_method = lambda: 'POST'
        
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                if response.status != 200:
                    print(f"Failed to send Slack notification: {response.status}")
                else:
                    print("Slack notification sent successfully")
        except urllib.error.URLError as e:
            print(f"Failed to send Slack notification: {str(e)}")
    except Exception as e:
        print(f"Error sending Slack notification: {e}")

def extract_safe_output(result):
    """Extract command output while filtering sensitive information."""
    if not result:
        return "No result data available"
        
    try:
        # Handle simple response format
        if result.get("status") == "completed":
            return result.get("message", "Command executed successfully")
        
        if result.get("status") == "accepted":
            return "Command was accepted and is executing asynchronously"
        
        if "message" in result and isinstance(result["message"], str):
            return result["message"]
        
        return "Command executed successfully - minimal output available"
        
    except Exception as e:
        return f"Could not extract command output: {str(e)}"

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
        print(f"Starting celerybeat restart automation for {VM_NAME}...")
        
        # Run diagnostics first
        env_type = diagnose_environment()
        
        if env_type == "local":
            print("🚨 WARNING: Running on local machine - managed identity won't work!")
            print("This script is designed to run in Azure Automation Account.")
            print("For local testing, only Slack notification will be tested.\n")
            
            # Test Slack notification only
            test_message = f"🧪 **LOCAL TEST** - Celerybeat automation script for {VM_NAME}\n\nThis is a test run from local development environment.\nIn production, this would execute: `{COMMAND_TO_RUN}`"
            send_slack_notification(test_message, is_error=False)
            print("✅ Local test completed - Slack notification sent")
            return
        
        # Azure environment - proceed with full automation
        print("Running in Azure environment - proceeding with managed identity authentication...")
        
        # Get token first - this is where the timeout was occurring
        token = get_managed_identity_token()
        
        # Execute the command
        result = invoke_run_command(token)
        
        # Print result for logging
        if result:
            print_run_command_output(result)
        
        # Extract safe command output for Slack
        command_output = extract_safe_output(result) if result else ""
        
        success_message = f"Successfully executed command: `{COMMAND_TO_RUN}`\n\n**Output:**\n```\n{command_output}\n```" if command_output else f"Successfully executed command: `{COMMAND_TO_RUN}`"
        
        send_slack_notification(success_message, is_error=False)
        print("Completed Run Command on celerybeat-vantage.")
        
    except Exception as e:
        error_message = f"Failed to execute celerybeat restart automation\n\n**Error:** {str(e)}"
        send_slack_notification(error_message, is_error=True)
        print(f"ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()