#!/bin/bash

# Common functions for AWS scripts

# Check if AWS SSO session is active, if not, prompt for login
check_aws_auth() {
    local profile="${1:-${AWS_PROFILE:-default}}"

    if ! aws sts get-caller-identity --profile "$profile" &> /dev/null; then
        # No active session — require a TTY to do the interactive SSO login flow
        if [ ! -t 0 ]; then
            echo "Error: AWS SSO session expired or not active for profile '$profile'." >&2
            echo "Run 'aws sso login --profile $profile' in a terminal first, then retry." >&2
            exit 1
        fi

        echo "AWS SSO session not active or expired. Initiating login..."
        echo "A browser window will open. Please verify the code shown below matches what appears in your browser."
        echo ""

        # Run aws sso login with direct terminal access to ensure verification code is visible
        # Redirect to /dev/tty to bypass any output capturing
        aws sso login --profile "$profile" < /dev/tty > /dev/tty 2>&1

        echo ""

        # Verify login was successful
        if ! aws sts get-caller-identity --profile "$profile" &> /dev/null; then
            echo "Error: AWS authentication failed" >&2
            exit 1
        fi
        echo ""
        echo "✓ Authentication successful"
        echo ""
    fi
}
