#!/bin/bash

# Exit on error
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
OUTPUT_FILE="${SCRIPT_DIR}/proxy-lambda.zip"

echo "Creating Lambda deployment package..."

# Check if zip command is available
if ! command -v zip &> /dev/null; then
    echo "Error: zip command not found. Please install zip."
    exit 1
fi

# Create deployment package
cd "${SCRIPT_DIR}"
zip -r "${OUTPUT_FILE}" index.js
echo "Deployment package created at: ${OUTPUT_FILE}"