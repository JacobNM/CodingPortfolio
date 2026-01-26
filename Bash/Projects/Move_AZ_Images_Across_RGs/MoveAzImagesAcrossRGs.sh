#!/usr/bin/env bash
set -euo pipefail

# Move managed VM images whose name contains a specified string from one resource group to another.
# Requirements: Azure CLI (az) logged in, and permissions to move images between resource groups.
# NOTE: Images are MOVED (not copied) - they will be removed from the source resource group.

readonly SCRIPT_NAME="$(basename "$0")"

# Initialize variables with defaults
SOURCE_RESOURCE_GROUP=""
DESTINATION_RESOURCE_GROUP=""
SUBSCRIPTION_ID=""
IMAGE_NAME_FILTER=""
IS_DRY_RUN=false
SKIP_CONFIRMATION=false

show_help() {
    cat << EOF
${SCRIPT_NAME} - Move Azure managed VM images between resource groups

SYNOPSIS
    ${SCRIPT_NAME} -s <source_rg> -d <dest_rg> [options]
    ${SCRIPT_NAME} --source <source_rg> --destination <dest_rg> [options]

DESCRIPTION
    Moves managed VM images whose names contain a specified filter string from a source 
    resource group to a destination resource group. You must specify a filter string
    to match image names. Images are MOVED (not copied) from source to destination.

OPTIONS
    -s, --source <name>         Source resource group name (required)
    -d, --destination <name>    Destination resource group name (required)
    -u, --subscription <id>     Azure subscription ID (optional, uses current context if omitted)
    -f, --filter <string>       String that must be contained in image names (required)
    -n, --dry-run              Preview mode - show what would be moved without executing
    -y, --yes                  Skip confirmation prompt and proceed automatically
    -h, --help                 Show this help message and exit

EXAMPLES
    # Move all images containing "2026" from source to destination RG
    ${SCRIPT_NAME} -s 2025-ImagePrep -d 2026-ImagePrep -f "2026"

    # Move images with custom filter in specific subscription
    ${SCRIPT_NAME} --source source-rg --destination dest-rg --subscription "12345678-1234-1234-1234-123456789012" --filter "ubuntu"

    # Preview what would be moved without executing
    ${SCRIPT_NAME} -s source-rg -d dest-rg -f "2026" --dry-run

    # Skip confirmation and proceed automatically
    ${SCRIPT_NAME} -s 2025-ImagePrep -d 2026-ImagePrep -f "2026" --yes

    # Using mixed short and long options
    ${SCRIPT_NAME} -s 2025-Images --destination 2026-Images -u "my-subscription-id" -f "2026" -n

REQUIREMENTS
    - Azure CLI installed and authenticated (run 'az login')
    - Read permissions on source resource group
    - Write permissions on destination resource group
    - IMPORTANT: Images will be MOVED (not copied) from source to destination

BACKWARD COMPATIBILITY
    For backward compatibility, positional arguments are still supported:
    ${SCRIPT_NAME} <source_rg> <dest_rg> <filter_string> [subscription_id] [--dry-run|-n]

EOF
}

# Parse command line arguments
if [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; then
    # Backward compatibility: if first argument doesn't start with -, use positional parsing
    SOURCE_RESOURCE_GROUP="${1:-}"
    DESTINATION_RESOURCE_GROUP="${2:-}"
    IMAGE_NAME_FILTER="${3:-}"
    SUBSCRIPTION_ID="${4:-}"
    if [[ "${5:-}" =~ ^(--dry-run|-n)$ ]]; then
        IS_DRY_RUN=true
    fi
else
    # Manual argument parsing (works on both BSD and GNU systems)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--source)
                if [[ -n "${2:-}" ]]; then
                    SOURCE_RESOURCE_GROUP="$2"
                    shift 2
                else
                    echo "Error: --source requires a value" >&2
                    show_help
                    exit 1
                fi
                ;;
            -d|--destination)
                if [[ -n "${2:-}" ]]; then
                    DESTINATION_RESOURCE_GROUP="$2"
                    shift 2
                else
                    echo "Error: --destination requires a value" >&2
                    show_help
                    exit 1
                fi
                ;;
            -u|--subscription)
                # Handle optional subscription parameter
                if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                    # Next argument exists and doesn't start with -, use it as subscription ID
                    SUBSCRIPTION_ID="$2"
                    shift 2
                elif [[ -n "${2:-}" && "$2" =~ ^- ]]; then
                    # Next argument is another flag, so -u was used without value
                    # Leave SUBSCRIPTION_ID empty to use current subscription
                    shift 1
                else
                    # No next argument, -u was the last argument
                    # Leave SUBSCRIPTION_ID empty to use current subscription  
                    shift 1
                fi
                ;;
            -f|--filter)
                if [[ -n "${2:-}" ]]; then
                    IMAGE_NAME_FILTER="$2"
                    shift 2
                else
                    echo "Error: --filter requires a value" >&2
                    show_help
                    exit 1
                fi
                ;;
            -n|--dry-run)
                IS_DRY_RUN=true
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                show_help
                exit 1
                ;;
            *)
                echo "Error: Unexpected argument: $1" >&2
                show_help
                exit 1
                ;;
        esac
    done
fi

# Validate required parameters
if [[ -z "$SOURCE_RESOURCE_GROUP" || -z "$DESTINATION_RESOURCE_GROUP" ]]; then
    echo "Error: Both source (-s/--source) and destination (-d/--destination) resource groups are required." >&2
    echo "" >&2
    show_help
    exit 1
fi

if [[ -z "$IMAGE_NAME_FILTER" ]]; then
    echo "Error: Image name filter (-f/--filter) is required." >&2
    echo "Specify a string that image names must contain (e.g., -f \"2026\")" >&2
    echo "" >&2
    show_help
    exit 1
fi

# Dry-run banner
if [[ "$IS_DRY_RUN" == true ]]; then
    echo "🔍 DRY RUN MODE: Will preview move operations without executing them"
    echo ""
fi

# Ensure user is logged into Azure CLI
echo "🔐 Verifying Azure CLI authentication..."
az account show >/dev/null 2>&1 || {
    echo "❌ Error: Not logged into Azure CLI. Please run: az login" >&2
    exit 1
}
echo "✅ Azure CLI authentication verified"

# Optionally set subscription context
if [[ -n "$SUBSCRIPTION_ID" ]]; then
    echo "🎯 Setting subscription context to: $SUBSCRIPTION_ID"
    az account set --subscription "$SUBSCRIPTION_ID"
    CURRENT_SUB_NAME=$(az account show --query name -o tsv)
    echo "✅ Using subscription: $CURRENT_SUB_NAME ($SUBSCRIPTION_ID)"
else
    CURRENT_SUB_INFO=$(az account show --query "{name:name, id:id}" -o tsv)
    echo "🎯 Using current subscription: $CURRENT_SUB_INFO"
fi

# Verify resource groups exist
echo ""
echo "🔍 Verifying resource groups exist..."
if ! az group show -n "$SOURCE_RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "❌ Error: Source resource group '$SOURCE_RESOURCE_GROUP' not found" >&2
    exit 1
fi
echo "✅ Source resource group '$SOURCE_RESOURCE_GROUP' found"

if ! az group show -n "$DESTINATION_RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "❌ Error: Destination resource group '$DESTINATION_RESOURCE_GROUP' not found" >&2
    exit 1
fi
echo "✅ Destination resource group '$DESTINATION_RESOURCE_GROUP' found"

echo ""
echo "🔍 Searching for managed images in '$SOURCE_RESOURCE_GROUP' containing '$IMAGE_NAME_FILTER'..."

# Get list of matching images
MATCHING_IMAGES=()
while IFS= read -r line; do
    [[ -n "$line" ]] && MATCHING_IMAGES+=("$line")
done < <(az image list -g "$SOURCE_RESOURCE_GROUP" \
    --query "[?contains(name, '${IMAGE_NAME_FILTER}')].name" -o tsv)

if [[ "${#MATCHING_IMAGES[@]}" -eq 0 ]]; then
    echo "ℹ️  No managed images found in '$SOURCE_RESOURCE_GROUP' containing '$IMAGE_NAME_FILTER'"
    echo "   You may want to:"
    echo "   - Check the image name filter: '$IMAGE_NAME_FILTER'"
    echo "   - Verify images exist in the source resource group"
    echo "   - List all images: az image list -g '$SOURCE_RESOURCE_GROUP' --query '[].name' -o table"
    exit 0
fi

echo "✅ Found ${#MATCHING_IMAGES[@]} matching image(s):"
for IMAGE_NAME in "${MATCHING_IMAGES[@]}"; do
    # Get image details for better output
    IMAGE_INFO=$(az image show -g "$SOURCE_RESOURCE_GROUP" -n "$IMAGE_NAME" --query '{location: location, id: id}' -o tsv)
    IMAGE_LOCATION=$(echo "$IMAGE_INFO" | cut -f1)
    echo "   📀 $IMAGE_NAME (location: $IMAGE_LOCATION)"
done

# Check for existing images in destination to avoid conflicts
echo ""
echo "🔍 Checking for existing images in destination resource group..."
declare -a EXISTING_CONFLICTS=()
for IMAGE_NAME in "${MATCHING_IMAGES[@]}"; do
    if az image show -g "$DESTINATION_RESOURCE_GROUP" -n "$IMAGE_NAME" >/dev/null 2>&1; then
        EXISTING_CONFLICTS+=("$IMAGE_NAME")
    fi
done

if [[ "${#EXISTING_CONFLICTS[@]}" -gt 0 ]]; then
    echo "⚠️  Warning: ${#EXISTING_CONFLICTS[@]} image(s) already exist in destination and will be skipped:"
    printf '   - %s\n' "${EXISTING_CONFLICTS[@]}"
fi

# Calculate how many will actually be processed
IMAGES_TO_MOVE=()
for IMAGE_NAME in "${MATCHING_IMAGES[@]}"; do
    # Use error handling to prevent script exit
    if az image show -g "$DESTINATION_RESOURCE_GROUP" -n "$IMAGE_NAME" >/dev/null 2>&1; then
        # Image exists in destination, skip it
        :
    else
        # Image doesn't exist in destination (or error occurred), add to move list
        IMAGES_TO_MOVE+=("$IMAGE_NAME")
    fi
done

if [[ "${#IMAGES_TO_MOVE[@]}" -eq 0 ]]; then
    echo "ℹ️ All matching images already exist in the destination resource group. Nothing to move."
    exit 0
fi

echo "📋 Summary:"
echo "   Source RG:      $SOURCE_RESOURCE_GROUP"
echo "   Destination RG: $DESTINATION_RESOURCE_GROUP"
echo "   Filter:         '$IMAGE_NAME_FILTER'"
echo "   Images to move: ${#IMAGES_TO_MOVE[@]}"
echo "   Will skip:      ${#EXISTING_CONFLICTS[@]} (already exist)"

if [[ "$IS_DRY_RUN" == true ]]; then
    echo ""
    echo "🔍 DRY RUN - Would move these images:"
    for IMAGE_NAME in "${IMAGES_TO_MOVE[@]}"; do
        IMAGE_INFO=$(az image show -g "$SOURCE_RESOURCE_GROUP" -n "$IMAGE_NAME" --query '{location: location, id: id}' -o tsv)
        IMAGE_LOCATION=$(echo "$IMAGE_INFO" | cut -f1)
        echo "   📀 $IMAGE_NAME -> $DESTINATION_RESOURCE_GROUP/$IMAGE_NAME (location: $IMAGE_LOCATION)"
    done
    echo ""
    echo "✨ Dry run complete. Use without --dry-run flag to execute the move operations."
    exit 0
fi

# Confirmation prompt (unless --yes flag is used)
echo ""
if [[ "$SKIP_CONFIRMATION" == true ]]; then
    echo "✅ Skipping confirmation (--yes flag used) - proceeding with image move operations..."
else
    read -r -p "🤔 Do you want to proceed with moving ${#IMAGES_TO_MOVE[@]} image(s)? [y/N] " confirmation
    case "$confirmation" in
        [yY]|[yY][eE][sS])
            echo "✅ Proceeding with image move operations..."
            ;;
        *)
            echo "❌ Operation cancelled by user"
            exit 0
            ;;
    esac
fi

echo ""
echo "🚀 Starting image move operations..."

# Track progress
TOTAL_IMAGES="${#IMAGES_TO_MOVE[@]}"
declare -i CURRENT_IMAGE=0
declare -i SUCCESSFUL_MOVES=0
declare -i FAILED_MOVES=0
declare -i SKIPPED_MOVES=0

for IMAGE_NAME in "${IMAGES_TO_MOVE[@]}"; do
    CURRENT_IMAGE+=1
    
    # Get source image details
    echo ""
    echo "📀 [$CURRENT_IMAGE/$TOTAL_IMAGES] Processing image: $IMAGE_NAME"
    
    # Get the source image ID for moving
    if ! SOURCE_IMAGE_ID=$(az image show -g "$SOURCE_RESOURCE_GROUP" -n "$IMAGE_NAME" --query 'id' -o tsv 2>/dev/null); then
        echo "   ❌ Error: Failed to retrieve image ID for $IMAGE_NAME"
        echo "      This may indicate the image no longer exists or access permissions have changed."
        FAILED_MOVES+=1
        continue
    fi
    
    echo "   🎯 Source:      $SOURCE_RESOURCE_GROUP/$IMAGE_NAME"
    echo "   🎯 Destination: $DESTINATION_RESOURCE_GROUP/$IMAGE_NAME"
    echo "   ⏳ Moving..."
    
    # Move the image using az resource move
    if az resource move \
        --destination-group "$DESTINATION_RESOURCE_GROUP" \
        --ids "$SOURCE_IMAGE_ID" \
        --only-show-errors 2>/dev/null; then
        echo "   ✅ Successfully moved image"
        SUCCESSFUL_MOVES+=1
    else
        echo "   ❌ Failed to move image: $IMAGE_NAME" >&2
        FAILED_MOVES+=1
    fi
done

echo ""
echo "🎉 Image move operations completed!"
echo "   📊 Processed: $CURRENT_IMAGE/$TOTAL_IMAGES images"
echo "   ✅ Successfully moved: $SUCCESSFUL_MOVES"
echo "   ❌ Failed to move: $FAILED_MOVES"
echo "   🎯 Destination resource group: $DESTINATION_RESOURCE_GROUP"
echo ""
echo "💡 You can verify the moved images with:"
echo "   az image list -g '$DESTINATION_RESOURCE_GROUP' --query '[].name' -o table"