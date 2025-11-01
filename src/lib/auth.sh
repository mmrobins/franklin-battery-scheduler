# Get an authentication token
function get_token() {
    if [ -f ".env" ]; then
        source .env
        if [ -n "$FRANKLIN_TOKEN" ]; then
            if [ "$DEBUG" = "true" ]; then
                echo "DEBUG: Using cached token from .env file." >&2
            fi
            echo "$FRANKLIN_TOKEN"
            return
        fi
    fi

    BASE_URL="https://energy.franklinwh.com/hes-gateway/terminal"

    if [ "$DEBUG" = "true" ]; then
        echo "DEBUG: Logging in to get auth token..." >&2
    fi

    # Get MD5 hash of password (using openssl on macOS)
    PASSWORD_HASH=$(echo -n "$FRANKLIN_PASSWORD" | openssl md5 | cut -d' ' -f2)

    if [ "$DEBUG" = "true" ]; then
        echo "DEBUG: Password hash: $PASSWORD_HASH" >&2
    fi

    # Login to get token
    LOGIN_CMD="curl -s -X POST \"$BASE_URL/initialize/appUserOrInstallerLogin\" -d \"account=$FRANKLIN_EMAIL\" -d \"password=$PASSWORD_HASH\" -d \"lang=en_US\" -d \"type=1\""

    if [ "$DEBUG" = "true" ]; then
        echo "DEBUG: Running login command:" >&2
        echo "DEBUG: $LOGIN_CMD" >&2
    fi

    LOGIN_RESPONSE=$(eval "$LOGIN_CMD")

    if [ "$DEBUG" = "true" ]; then
        echo "DEBUG: Login response: $LOGIN_RESPONSE" >&2
    fi

    # Extract token using grep and sed
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | sed 's/"token":"//' | sed 's/"//')

    if [ -z "$TOKEN" ]; then
        echo "Error: Failed to get authentication token" >&2
        echo "Response: $LOGIN_RESPONSE" >&2
        exit 1
    fi

    echo "FRANKLIN_TOKEN=$TOKEN" > .env
    echo "$TOKEN"
}
