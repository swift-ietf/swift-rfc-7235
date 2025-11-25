#!/bin/bash

# Enhanced setup script for new RFC repository
# Usage: ./Scripts/setup-rfc.sh <RFC_NUMBER> <RFC_TITLE> [AUTHOR_NAME] [DEPENDENCIES...] [OPTIONS]

set -e

# Default values
AUTHOR_NAME="Generated"
CREATION_DATE=$(date +"%Y-%m-%d")
DEPENDENCIES=()
SOURCE_DIR=""
SKIP_TEMPLATES=false

# Function to show usage
show_usage() {
    echo "Usage: $0 <RFC_NUMBER> <RFC_TITLE> [AUTHOR_NAME] [OPTIONS]"
    echo "Example: $0 2822 'Internet Message Format' 'John Doe'"
    echo ""
    echo "Options:"
    echo "  --deps RFC1,RFC2,RFC3     Comma-separated list of RFC dependencies"
    echo "  --source /path/to/source  Path to existing source directory to copy from"
    echo "  --skip-templates          Skip creating template files (use with --source)"
    echo "  --author 'Author Name'    Override default author name"
    echo ""
    echo "Examples:"
    echo "  $0 5322 'Internet Message Format' --deps 1123,5321"
    echo "  $0 6531 'SMTP Extension' --source /path/to/sources --skip-templates"
}

# Parse arguments
if [ $# -lt 2 ]; then
    show_usage
    exit 1
fi

RFC_NUMBER=$1
RFC_TITLE=$2
shift 2

# Parse remaining arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --deps)
            IFS=',' read -ra DEPENDENCIES <<< "$2"
            shift 2
            ;;
        --source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        --skip-templates)
            SKIP_TEMPLATES=true
            shift
            ;;
        --author)
            AUTHOR_NAME="$2"
            shift 2
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            if [[ -z "$AUTHOR_NAME" || "$AUTHOR_NAME" == "Generated" ]]; then
                AUTHOR_NAME="$1"
            fi
            shift
            ;;
    esac
done

echo "Setting up RFC $RFC_NUMBER: $RFC_TITLE"
echo "Author: $AUTHOR_NAME"
echo "Date: $CREATION_DATE"
echo "Dependencies: ${DEPENDENCIES[*]}"

# Validate RFC number
if ! [[ "$RFC_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "Error: RFC_NUMBER must be a number"
    exit 1
fi

# Function to process template files with better sed handling
process_template() {
    local file=$1
    local new_file="${file%.template}"
    
    # Use | as delimiter to avoid conflicts with / in dates and titles
    sed -e "s|XXXX|$RFC_NUMBER|g" \
        -e "s|RFC_TITLE|$RFC_TITLE|g" \
        -e "s|RFC_AUTHOR_NAME|$AUTHOR_NAME|g" \
        -e "s|RFC_CREATION_DATE|$CREATION_DATE|g" \
        "$file" > "$new_file"
    rm "$file"
    echo "Processed: $new_file"
}

# Process all template files unless skipping
if [ "$SKIP_TEMPLATES" = false ]; then
    find . -name "*.template" -type f | while read -r file; do
        process_template "$file"
    done
else
    echo "Skipping template processing as requested"
fi

# Rename directories
if [ -d "Sources/RFC_XXXX" ]; then
    mv "Sources/RFC_XXXX" "Sources/RFC_$RFC_NUMBER"
    echo "Renamed: Sources/RFC_$RFC_NUMBER"
fi

if [ -d "Tests/RFC_XXXX Tests" ]; then
    mv "Tests/RFC_XXXX Tests" "Tests/RFC_${RFC_NUMBER} Tests"
    echo "Renamed: Tests/RFC_${RFC_NUMBER} Tests"
fi

# Copy from source directory if provided
if [ -n "$SOURCE_DIR" ]; then
    echo "Copying implementations from source directory..."
    
    # Copy source files
    if [ -d "$SOURCE_DIR/Sources/RFC $RFC_NUMBER" ]; then
        cp -r "$SOURCE_DIR/Sources/RFC $RFC_NUMBER"/* "Sources/RFC_$RFC_NUMBER/"
        echo "Copied source files from RFC $RFC_NUMBER"
    fi
    
    # Copy test files
    if [ -d "$SOURCE_DIR/Tests/RFC $RFC_NUMBER Tests" ]; then
        cp -r "$SOURCE_DIR/Tests/RFC $RFC_NUMBER Tests"/* "Tests/RFC_${RFC_NUMBER} Tests/"
        echo "Copied test files from RFC $RFC_NUMBER Tests"
    fi
    
    # Clean up template files if they exist
    rm -f "Sources/RFC_$RFC_NUMBER/RFC_XXXX.swift"
    rm -f "Tests/RFC_${RFC_NUMBER} Tests/RFC_XXXX Tests.swift"
    echo "Cleaned up template placeholder files"
fi

# Update Package.swift with dependencies
if [ ${#DEPENDENCIES[@]} -gt 0 ]; then
    echo "Updating Package.swift with dependencies..."
    
    # Build dependency strings
    PACKAGE_DEPS=""
    TARGET_DEPS=""
    EXTENSIONS=""
    
    for dep in "${DEPENDENCIES[@]}"; do
        if [ -n "$PACKAGE_DEPS" ]; then
            PACKAGE_DEPS="$PACKAGE_DEPS,\n        "
            TARGET_DEPS="$TARGET_DEPS,\n                "
            EXTENSIONS="$EXTENSIONS\n    "
        fi
        
        PACKAGE_DEPS="$PACKAGE_DEPS.package(url: \"https://github.com/swift-web-standards/swift-rfc-$dep.git\", branch: \"main\")"
        TARGET_DEPS="$TARGET_DEPS.rfc$dep"
        EXTENSIONS="$EXTENSIONS static var rfc$dep: Self { .product(name: \"RFC_$dep\", package: \"swift-rfc-$dep\") }"
    done
    
    # Update Package.swift dependencies section
    sed -i '' "s|// Add RFC dependencies here as needed.*|$PACKAGE_DEPS,|" Package.swift
    
    # Update target dependencies
    sed -i '' "s|// Add target dependencies here|$TARGET_DEPS|" Package.swift
    
    # Add dependency extensions
    sed -i '' "s|static var rfc$RFC_NUMBER: Self { .target(name: .rfc$RFC_NUMBER) }|static var rfc$RFC_NUMBER: Self { .target(name: .rfc$RFC_NUMBER) }\n$EXTENSIONS|" Package.swift
    
    echo "Updated Package.swift with dependencies: ${DEPENDENCIES[*]}"
fi

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
    git init
    echo "Initialized git repository"
fi

echo ""
echo "✅ RFC $RFC_NUMBER setup complete!"
echo ""
echo "Next steps:"
echo "1. Review and commit the generated files"
echo "2. Create GitHub repository: swift-rfc-$RFC_NUMBER"
echo "3. Push to GitHub"
if [ -n "$SOURCE_DIR" ]; then
    echo "4. Implementation files have been copied and are ready for use"
else
    echo "4. Start implementing RFC $RFC_NUMBER types in Sources/RFC_$RFC_NUMBER/"
fi
echo ""
echo "Dependencies configured: ${DEPENDENCIES[*]}"