SOC=${args[soc]}
MODE_ID=${args[mode]:-self}

# Validate MODE_ID and set currendId and workMode
case "$MODE_ID" in
    "tou") # Time of Use
        CURREND_ID="162382"
        WORK_MODE="1"
        MODE_NAME="Time of Use"
        ;;
    "self") # Self Consumption
        CURREND_ID="150521"
        WORK_MODE="2"
        MODE_NAME="Self Consumption"
        ;;
    "backup") # Emergency Backup
        CURREND_ID="150953"
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

BASE_URL="https://energy.franklinwh.com/hes-gateway/terminal"

  echo "Logging in to get token..."
if [ -z "$TOKEN" ]; then
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