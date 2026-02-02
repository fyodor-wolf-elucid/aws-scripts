#!/bin/bash

# Common functions for AWS scripts

# Check if AWS SSO session is active, if not, prompt for login
check_aws_auth() {
    local profile="${1:-${AWS_PROFILE:-default}}"

    if ! aws sts get-caller-identity --profile "$profile" &> /dev/null; then
        echo "AWS SSO session not active or expired. Initiating login..."
        echo ""
        aws sso login --profile "$profile"

        # Verify login was successful
        if ! aws sts get-caller-identity --profile "$profile" &> /dev/null; then
            echo "Error: AWS authentication failed"
            exit 1
        fi
        echo ""
        echo "✓ Authentication successful"
        echo ""
    fi
}
