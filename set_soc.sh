#!/bin/bash

# Check if SOC argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <soc_percentage>"
    echo "Example: $0 65"
    exit 1
fi

SOC=$1

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

# Login to get token
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/initialize/appUserOrInstallerLogin" \
    -d "account=$FRANKLIN_EMAIL" \
    -d "password=$PASSWORD_HASH" \
    -d "lang=en_US" \
    -d "type=1")

# Extract token using grep and sed
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | sed 's/"token":"//' | sed 's/"//')

if [ -z "$TOKEN" ]; then
    echo "Error: Failed to get authentication token"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo "Setting self-consumption mode with ${SOC}% SOC..."

# Set self-consumption mode with specified SOC
RESPONSE=$(curl -s -X POST "$BASE_URL/tou/updateTouMode" \
    -H "loginToken: $TOKEN" \
    -d "currendId=9323" \
    -d "gatewayId=$FRANKLIN_GATEWAY_ID" \
    -d "oldIndex=1" \
    -d "soc=$SOC" \
    -d "stromEn=1" \
    -d "workMode=2")

# Check if successful by looking for "code":200
SUCCESS=$(echo "$RESPONSE" | grep -q '"code":200' && echo "success" || echo "failed")

if [ "$SUCCESS" = "success" ]; then
    echo "✓ Successfully set self-consumption mode with ${SOC}% SOC"
else
    echo "✗ Failed to set mode. Response:"
    echo "$RESPONSE"
    exit 1
fi
