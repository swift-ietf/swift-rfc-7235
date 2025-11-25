#!/bin/bash

# Batch RFC setup script
# Creates multiple RFC packages from existing source directory
# Usage: ./Scripts/setup-batch-rfcs.sh <SOURCE_DIR> <AUTHOR_NAME> <RFC_DEFINITIONS_FILE>

set -e

if [ $# -lt 3 ]; then
    echo "Usage: $0 <SOURCE_DIR> <AUTHOR_NAME> <RFC_DEFINITIONS_FILE>"
    echo ""
    echo "RFC_DEFINITIONS_FILE format (one per line):"
    echo "RFC_NUMBER:RFC_TITLE:DEPENDENCIES"
    echo ""
    echo "Example:"
    echo "1035:Domain Names Implementation and Specification:"
    echo "1123:Requirements for Internet Hosts Application and Support:1035"
    echo "5321:Simple Mail Transfer Protocol:1123"
    echo "5322:Internet Message Format:1123,5321"
    echo "6531:SMTP Extension for Internationalized Email:1123,5321,5322"
    echo "2822:Internet Message Format:"
    exit 1
fi

SOURCE_DIR="$1"
AUTHOR_NAME="$2"
RFC_DEFINITIONS_FILE="$3"

if [ ! -f "$RFC_DEFINITIONS_FILE" ]; then
    echo "Error: RFC definitions file not found: $RFC_DEFINITIONS_FILE"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory not found: $SOURCE_DIR"
    exit 1
fi

echo "Starting batch RFC setup..."
echo "Source directory: $SOURCE_DIR"
echo "Author: $AUTHOR_NAME"
echo "Definitions: $RFC_DEFINITIONS_FILE"
echo ""

# Read and process each RFC definition
while IFS=':' read -r rfc_number rfc_title rfc_deps; do
    # Skip empty lines and comments
    if [[ -z "$rfc_number" || "$rfc_number" == \#* ]]; then
        continue
    fi
    
    echo "Setting up RFC $rfc_number: $rfc_title"
    
    # Create the RFC directory
    RFC_DIR="swift-rfc-$rfc_number"
    
    if [ -d "$RFC_DIR" ]; then
        echo "Warning: Directory $RFC_DIR already exists. Skipping..."
        continue
    fi
    
    # Copy template
    cp -r swift-rfc-template "$RFC_DIR"
    cd "$RFC_DIR"
    
    # Build setup command
    SETUP_CMD="./Scripts/setup-rfc.sh $rfc_number \"$rfc_title\" --author \"$AUTHOR_NAME\" --source \"$SOURCE_DIR\" --skip-templates"
    
    # Add dependencies if they exist
    if [ -n "$rfc_deps" ]; then
        SETUP_CMD="$SETUP_CMD --deps $rfc_deps"
    fi
    
    # Run setup
    eval "$SETUP_CMD"
    
    # Initialize git and make initial commit
    git add .
    git commit -m "Initial commit for RFC $rfc_number: $rfc_title

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    cd ..
    echo "✅ RFC $rfc_number setup complete"
    echo ""
    
done < "$RFC_DEFINITIONS_FILE"

echo "🎉 Batch RFC setup complete!"
echo ""
echo "Created RFC packages:"
ls -1 swift-rfc-* | grep -v template || true