DATE=${args[--date]}

# Set default date (today)
if [ -z "$DATE" ]; then
    DATE=$(date +%Y-%m-%d)
fi

BASE_URL="https://energy.franklinwh.com"
ANALYTICS_DIR="analytics"
CSV_FILE="$ANALYTICS_DIR/${DATE}_franklin_fine_grained_analytics.csv"

mkdir -p $ANALYTICS_DIR

echo "Fetching fine-grained analytics for $DATE..."

# Get auth token
TOKEN=$(get_token)
if [ -z "$TOKEN" ]; then
    exit 1
fi

# Write CSV header
echo "deviceTime,powerSolarHome,powerSolarGird,powerSolarFhp,powerGirdFhp,powerGirdHome,powerFhpGird,powerFhpHome,powerGenFhp,powerGenHome" > $CSV_FILE

# Fetch data
API_RESPONSE=$(curl -s -X GET "$BASE_URL/api-energy/power/getFhpPowerByDay?gatewayId=$FRANKLIN_GATEWAY_ID&dayTime=$DATE" -H "loginToken: $TOKEN")

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: API Response for $DATE:"
    echo "$API_RESPONSE"
fi

# Parse JSON and append to CSV
echo "$API_RESPONSE" | jq -r '.result | [.deviceTimeArray, .powerSolarHomeArray, .powerSolarGirdArray, .powerSolarFhpArray, .powerGirdFhpArray, .powerGirdHomeArray, .powerFhpGirdArray, .powerFhpHomeArray, .powerGenFhpArray, .powerGenHomeArray] | transpose | .[] | @csv' >> $CSV_FILE

echo "Fine-grained analytics data saved to $CSV_FILE"