#!/bin/bash

# Enable debug mode if DEBUG=true
if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Debug mode enabled"
fi

# Check required environment variables
if [ -z "$FRANKLIN_EMAIL" ] || [ -z "$FRANKLIN_PASSWORD" ]; then
    echo "Error: Required environment variables not set: FRANKLIN_EMAIL, FRANKLIN_PASSWORD"
    exit 1
fi

BASE_URL="https://energy.franklinwh.com/hes-gateway/terminal"

if [ "$DEBUG" = "true" ]; then
    echo "DEBUG: Logging in to get token..."
fi

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

if [ -z "$TOKEN" ]; then
    echo "Error: Failed to get authentication token"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo "$TOKEN"
