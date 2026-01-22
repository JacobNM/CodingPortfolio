#!/usr/bin/env bash
set -euo pipefail

# Copy managed VM images whose name contains a specified string from one resource group to another.
# Requirements: Azure CLI (az) logged in, and permissions to read/write images in both resource groups.

readonly SCRIPT_NAME="$(basename "$0")"

# Parse command line arguments
SOURCE_RESOURCE_GROUP="${1:-}"
DESTINATION_RESOURCE_GROUP="${2:-}"
SUBSCRIPTION_ID="${3:-}"           # optional; if empty, uses current az context
IMAGE_NAME_FILTER="${4:-2026}"     # optional; default "2026"
DRY_RUN="${5:-}"                   # optional; set to "--dry-run" or "-n" for preview mode

show_help() {
    cat << EOF
${SCRIPT_NAME} - Copy Azure managed VM images between resource groups

SYNOPSIS
    ${SCRIPT_NAME} <source_rg> <dest_rg> [subscription_id] [name_filter] [--dry-run|-n]

DESCRIPTION
    Copies managed VM images whose names contain a specified filter string from a source 
    resource group to a destination resource group. By default, searches for images 
    containing "2026" in the name.

PARAMETERS
    source_rg       Source resource group name (required)
    dest_rg         Destination resource group name (required)
    subscription_id Azure subscription ID (optional, uses current context if omitted)
    name_filter     String that must be contained in image names (default: "2026")
    --dry-run, -n   Preview mode - show what would be copied without executing (optional)

EXAMPLES
    # Copy all images containing "2026" from source to destination RG
    ${SCRIPT_NAME} 2025-ImagePrep 2026-ImagePrep

    # Copy images with custom filter in specific subscription
    ${SCRIPT_NAME} source-rg dest-rg "12345678-1234-1234-1234-123456789012" "ubuntu"

    # Preview what would be copied without executing
    ${SCRIPT_NAME} source-rg dest-rg "" "2026" --dry-run

REQUIREMENTS
    - Azure CLI installed and authenticated (run 'az login')
    - Read permissions on source resource group
    - Write permissions on destination resource group

EOF
}

# Show help if requested
if [[ "${1:-}" =~ ^(-h|--help)$ ]]; then
    show_help
    exit 0
fi

# Validate required parameters
if [[ -z "$SOURCE_RESOURCE_GROUP" || -z "$DESTINATION_RESOURCE_GROUP" ]]; then
    echo "Error: Both source and destination resource groups are required." >&2
    echo "" >&2
    show_help
    exit 1
fi

# Check if this is a dry run
IS_DRY_RUN=false
if [[ "$DRY_RUN" =~ ^(--dry-run|-n)$ ]]; then
    IS_DRY_RUN=true
    echo "🔍 DRY RUN MODE: Will preview operations without executing them"
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
mapfile -t MATCHING_IMAGES < <(
    az image list -g "$SOURCE_RESOURCE_GROUP" \
        --query "[?contains(name, '${IMAGE_NAME_FILTER}')].name" -o tsv
)

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
    IMAGE_LOCATION=$(az image show -g "$SOURCE_RESOURCE_GROUP" -n "$IMAGE_NAME" --query location -o tsv)
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
IMAGES_TO_COPY=()
for IMAGE_NAME in "${MATCHING_IMAGES[@]}"; do
    if ! az image show -g "$DESTINATION_RESOURCE_GROUP" -n "$IMAGE_NAME" >/dev/null 2>&1; then
        IMAGES_TO_COPY+=("$IMAGE_NAME")
    fi
done

if [[ "${#IMAGES_TO_COPY[@]}" -eq 0 ]]; then
    echo "ℹ️  All matching images already exist in the destination resource group. Nothing to do."
    exit 0
fi

echo "📋 Summary:"
echo "   Source RG:      $SOURCE_RESOURCE_GROUP"
echo "   Destination RG: $DESTINATION_RESOURCE_GROUP"
echo "   Filter:         '$IMAGE_NAME_FILTER'"
echo "   Images to copy: ${#IMAGES_TO_COPY[@]}"
echo "   Will skip:      ${#EXISTING_CONFLICTS[@]} (already exist)"

if [[ "$IS_DRY_RUN" == true ]]; then
    echo ""
    echo "🔍 DRY RUN - Would copy these images:"
    for IMAGE_NAME in "${IMAGES_TO_COPY[@]}"; do
        IMAGE_LOCATION=$(az image show -g "$SOURCE_RESOURCE_GROUP" -n "$IMAGE_NAME" --query location -o tsv)
        echo "   📀 $IMAGE_NAME -> $DESTINATION_RESOURCE_GROUP/$IMAGE_NAME (location: $IMAGE_LOCATION)"
    done
    echo ""
    echo "✨ Dry run complete. Use without --dry-run flag to execute the copy operations."
    exit 0
fi

# Confirmation prompt
echo ""
read -r -p "🤔 Do you want to proceed with copying ${#IMAGES_TO_COPY[@]} image(s)? [y/N] " confirmation
case "$confirmation" in
    [yY]|[yY][eE][sS])
        echo "✅ Proceeding with image copy operations..."
        ;;
    *)
        echo "❌ Operation cancelled by user"
        exit 0
        ;;
esac

echo ""
echo "🚀 Starting image copy operations..."

# Track progress
TOTAL_IMAGES="${#IMAGES_TO_COPY[@]}"
CURRENT_IMAGE=0

for IMAGE_NAME in "${IMAGES_TO_COPY[@]}"; do
    ((CURRENT_IMAGE++))
    
    # Get source image details
    echo ""
    echo "📀 [$CURRENT_IMAGE/$TOTAL_IMAGES] Processing image: $IMAGE_NAME"
    
    SOURCE_IMAGE_ID=$(az image show -g "$SOURCE_RESOURCE_GROUP" -n "$IMAGE_NAME" --query id -o tsv)
    IMAGE_LOCATION=$(az image show -g "$SOURCE_RESOURCE_GROUP" -n "$IMAGE_NAME" --query location -o tsv)
    
    # Use the same name in destination (modify this if you want different naming)
    DESTINATION_IMAGE_NAME="$IMAGE_NAME"
    
    echo "   🎯 Source:      $SOURCE_RESOURCE_GROUP/$IMAGE_NAME"
    echo "   🎯 Destination: $DESTINATION_RESOURCE_GROUP/$DESTINATION_IMAGE_NAME"
    echo "   📍 Location:    $IMAGE_LOCATION"
    echo "   ⏳ Copying..."
    
    # Perform the copy operation with error handling
    if az image create \
        -g "$DESTINATION_RESOURCE_GROUP" \
        -n "$DESTINATION_IMAGE_NAME" \
        -l "$IMAGE_LOCATION" \
        --source "$SOURCE_IMAGE_ID" \
        --only-show-errors >/dev/null 2>&1; then
        echo "   ✅ Successfully copied image"
    else
        echo "   ❌ Failed to copy image: $IMAGE_NAME" >&2
        # Continue with other images rather than exiting
    fi
done

echo ""
echo "🎉 Image copy operations completed!"
echo "   📊 Processed: $CURRENT_IMAGE/$TOTAL_IMAGES images"
echo "   🎯 Destination resource group: $DESTINATION_RESOURCE_GROUP"
echo ""
echo "💡 You can verify the copied images with:"
echo "   az image list -g '$DESTINATION_RESOURCE_GROUP' --query '[].name' -o table"