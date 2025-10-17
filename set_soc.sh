#!/bin/bash

# Enable debug mode if DEBUG=true
if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Debug mode enabled"
fi

# Parse arguments
DEFAULT_MODE="self" # Self Consumption
MODE_ID="$DEFAULT_MODE"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <soc_percentage> [mode_name]"
    echo "Example: $0 65"
    echo "Example: $0 80 tou (for Time of Use)"
    exit 1
elif [ $# -eq 1 ]; then
    SOC=$1
elif [ $# -eq 2 ]; then
    SOC=$1
    MODE_ID=$2
else
    echo "Error: Too many arguments."
    echo "Usage: $0 <soc_percentage> [mode_id]"
    exit 1
fi

# Validate MODE_ID and set currendId and workMode
case "$MODE_ID" in
    "tou") # Time of Use
        CURREND_ID="9322"
        WORK_MODE="1"
        MODE_NAME="Time of Use"
        ;;
    "self") # Self Consumption
        CURREND_ID="9323"
        WORK_MODE="2"
        MODE_NAME="Self Consumption"
        ;;
    "backup") # Emergency Backup
        CURREND_ID="9324"
        WORK_MODE="3"
        MODE_NAME="Emergency Backup"
        ;;
    *)
        echo "Error: Invalid mode_id. Allowed values are 'tou', 'self', or 'backup'."
        exit 1
        ;;
esac

# Validate SOC is a number between 0 and 100
if ! [[ "$SOC" =~ ^[0-9]+$ ]] || [ "$SOC" -lt 0 ] || [ "$SOC" -gt 100 ]; then
    echo "Error: SOC must be a number between 0 and 100"
    exit 1
fi

# Check required environment variables
if [ -z "$FRANKLIN_EMAIL" ] || [ -z "$FRANKLIN_PASSWORD" ] || [ -z "$FRANKLIN_GATEWAY_ID" ]; then
    echo "Error: Required environment variables not set:"
    echo "  FRANKLIN_EMAIL"
    echo "  FRANKLIN_PASSWORD" 
    echo "  FRANKLIN_GATEWAY_ID"
    exit 1
fi

BASE_URL="https://energy.franklinwh.com/hes-gateway/terminal"

echo "Logging in to get token..."

# Get MD5 hash of password (using openssl on macOS)
PASSWORD_HASH=$(echo -n "$FRANKLIN_PASSWORD" | openssl md5 | cut -d' ' -f2)

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Password hash: $PASSWORD_HASH"
fi

# Login to get token
LOGIN_CMD="curl -s -X POST \"$BASE_URL/initialize/appUserOrInstallerLogin\" -d \"account=$FRANKLIN_EMAIL\" -d \"password=$PASSWORD_HASH\" -d \"lang=en_US\" -d \"type=1\""

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Running login command:"
    echo "DEBUG: $LOGIN_CMD"
fi

LOGIN_RESPONSE=$(eval "$LOGIN_CMD")

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Login response: $LOGIN_RESPONSE"
fi

# Extract token using grep and sed
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | sed 's/"token":"//' | sed 's/"//')

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Extracted token: $TOKEN"
fi

if [ -z "$TOKEN" ]; then
    echo "Error: Failed to get authentication token"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo "Setting ${MODE_NAME} mode with ${SOC}% SOC..."

# Set self-consumption mode with specified SOC
if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Setting SOC URL: $BASE_URL/tou/updateTouMode"
    echo "DEBUG: Gateway ID: $FRANKLIN_GATEWAY_ID"
    echo "DEBUG: SOC: $SOC"
fi

SOC_CMD="curl -s -X POST \"$BASE_URL/tou/updateTouMode\" -H \"loginToken: $TOKEN\" -H \"Content-Type: application/x-www-form-urlencoded\" -d \"currendId=$CURREND_ID\" -d \"gatewayId=$FRANKLIN_GATEWAY_ID\" -d \"lang=EN_US\" -d \"oldIndex=1\" -d \"soc=$SOC\" -d \"stromEn=1\" -d \"workMode=$WORK_MODE\""

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Running SOC update command:"
    echo "DEBUG: $SOC_CMD"
fi

RESPONSE=$(eval "$SOC_CMD")

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Set SOC response: $RESPONSE"
fi

# Check if successful by looking for "code":200
SUCCESS=$(echo "$RESPONSE" | grep -q '"code":200' && echo "success" || echo "failed")

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Success check result: $SUCCESS"
fi

if [ "$SUCCESS" = "success" ]; then
    echo "✓ Successfully set ${MODE_NAME} mode with ${SOC}% SOC"
else
    echo "✗ Failed to set ${MODE_NAME} mode. Response:"
    echo "$RESPONSE"
    exit 1
fi
