TOKEN=$(get_token)
if [ -z "$TOKEN" ]; then
    exit 1
fi

BASE_URL="https://energy.franklinwh.com"

API_RESPONSE=$(curl -s -X GET "$BASE_URL/hes-gateway/terminal/getDeviceCompositeInfo?gatewayId=$FRANKLIN_GATEWAY_ID&refreshFlag=1" -H "loginToken: $TOKEN")

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: API Response:"
    echo "$API_RESPONSE"
fi

SOC=$(echo "$API_RESPONSE" | jq -r '.result.runtimeData.soc')
MODE=$(echo "$API_RESPONSE" | jq -r '.result.runtimeData.mode')
KWH_USED_TODAY=$(echo "$API_RESPONSE" | jq -r '.result.runtimeData.kwh_load')
KWH_PRODUCED_TODAY=$(echo "$API_RESPONSE" | jq -r '.result.runtimeData.kwh_sun')
PANEL_CONSUMING=$(echo "$API_RESPONSE" | jq -r '.result.runtimeData.p_load')
PANEL_PRODUCING=$(echo "$API_RESPONSE" | jq -r '.result.runtimeData.p_sun')
GRID_DRAW=$(echo "$API_RESPONSE" | jq -r '.result.runtimeData.p_uti')

# Get the currently set SOC values for each mode from the TOU List V2 endpoint
TOU_LIST_RESPONSE=$(curl -s -X POST "$BASE_URL/hes-gateway/terminal/tou/getGatewayTouListV2?gatewayId=$FRANKLIN_GATEWAY_ID&showType=1" -H "loginToken: $TOKEN" -H "Content-Type: application/json" -d "")

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: TOU List V2 Response:"
    echo "$TOU_LIST_RESPONSE"
fi

# Extract the currently set SOC for the current mode (this represents the minimum SOC setting)
# From the API response, the 'soc' field contains the currently set SOC value for each mode
case "$MODE" in
    "150521")  # Self Consumption
        MIN_SOC=$(echo "$TOU_LIST_RESPONSE" | jq -r '.result?.list[]? | select(.id == 150521) | .soc // empty')
        ;;
    "162382")  # Time of Use
        MIN_SOC=$(echo "$TOU_LIST_RESPONSE" | jq -r '.result?.list[]? | select(.id == 162382) | .soc // empty')
        ;;
    "150953")  # Emergency Backup
        MIN_SOC=$(echo "$TOU_LIST_RESPONSE" | jq -r '.result?.list[]? | select(.id == 150953) | .soc // empty')
        ;;
    *)
        # For any other mode, try to get the SOC regardless of mode
        MIN_SOC=$(echo "$TOU_LIST_RESPONSE" | jq -r '.result?.list[]? | .soc // empty' | head -n 1)
        ;;
esac

case "$MODE" in
    "150521")
        MODE_NAME="Self Consumption"
        ;;
    "162382")
        MODE_NAME="Time of Use"
        ;;
    "150953")
        MODE_NAME="Emergency Backup"
        ;;
    *)
        MODE_NAME="Unknown"
        ;;
esac

echo "SOC: $SOC%"
if [ -n "$MIN_SOC" ] && [ "$MIN_SOC" != "null" ] && [ "$MIN_SOC" != "empty" ]; then
    echo "Min SOC: $MIN_SOC%"
else
    # Provide an informative message about where min SOC is usually configured
    echo "Min SOC: Not available (typically configured via app at 20%)"
fi
echo "Mode: $MODE_NAME"
echo "kWh Used Today: $KWH_USED_TODAY"
echo "kWh Produced Today: $KWH_PRODUCED_TODAY"
echo "Home Consuming: $PANEL_CONSUMING kW"
echo "Panel Producing: $PANEL_PRODUCING kW"

if (( $(echo "$GRID_DRAW > 0" | bc -l) )); then
    echo "Grid Draw: $GRID_DRAW kW"
else
    echo "Grid Send: $(echo "$GRID_DRAW * -1" | bc -l) kW"
fi
