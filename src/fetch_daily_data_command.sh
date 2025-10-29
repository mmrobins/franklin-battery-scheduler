START_DATE=${args[--start-date]}
END_DATE=${args[--end-date]}

# Set default date range (last 7 days)
if [ -z "$START_DATE" ]; then
    START_DATE=$(date -v-7d +%Y-%m-%d)
fi
if [ -z "$END_DATE" ]; then
    END_DATE=$(date +%Y-%m-%d)
fi

BASE_URL="https://energy.franklinwh.com"
ANALYTICS_DIR="analytics"
CSV_FILE="$ANALYTICS_DIR/${START_DATE}_to_${END_DATE}_franklin_daily_analytics.csv"

mkdir -p $ANALYTICS_DIR

echo "Fetching daily analytics from $START_DATE to $END_DATE..."

# Get auth token
TOKEN=$(get_token)
if [ -z "$TOKEN" ]; then
    exit 1
fi

# Write CSV header
echo "deviceTime,kwhSu,kwhGen,kwhUtiIn,kwhUtiOut,kwhFhpChg,kwhFhpDi,kwhLoad,kwhGridLoad,kwhSolarLoad,kwhFhpLoad,kwhGenLoad,gridChBat,batOutGrid,genChBat,soChBat,soOutGrid" > $CSV_FILE

# Loop through dates
CURRENT_DATE=$START_DATE
while [ "$CURRENT_DATE" != "$END_DATE" ]; do
    echo "Fetching data for $CURRENT_DATE..."

    # Fetch data for the current date
    API_RESPONSE=$(curl -s -X GET "$BASE_URL/api-energy/electric/getFhpElectricData?gatewayId=$FRANKLIN_GATEWAY_ID&type=1&dayTime=$CURRENT_DATE" -H "loginToken: $TOKEN")

    # Parse JSON and append to CSV
    echo "$API_RESPONSE" | jq -r '.result | [.deviceTimeArray, .kwhSuArray, .kwhGenArray, .kwhUtiInArray, .kwhUtiOutArray, .kwhFhpChgArray, .kwhFhpDiArray, .kwhLoadArray, .kwhGridLoadArray, .kwhSolarLoadArray, .kwhFhpLoadArray, .kwhGenLoadArray, .gridChBatArray, .batOutGridArray, .genChBatArray, .soChBatArray, .soOutGridArray] | transpose | .[] | @csv' >> $CSV_FILE

    CURRENT_DATE=$(date -j -v+1d -f "%Y-%m-%d" "$CURRENT_DATE" +%Y-%m-%d)
done

echo "Daily analytics data saved to $CSV_FILE"