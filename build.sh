#!/bin/bash

# Portfolio Build Script
# This script helps maintain the condensed portfolio structure

echo "🚀 Starting Portfolio Build Process..."

# Create necessary directories
mkdir -p components

# Check for duplicate content across files
echo "📊 Analyzing code duplication..."

# Function to find duplicate HTML blocks
find_duplicates() {
    echo "Checking for duplicate header sections..."
    grep -l "<header>" *.html | wc -l
    
    echo "Checking for duplicate footer sections..."
    grep -l "<footer>" *.html | wc -l
    
    echo "Checking for duplicate contact sections..."
    grep -l "Let's Connect" *.html | wc -l
}

# Run analysis
find_duplicates

# Optimize images (if needed)
echo "🖼️  Checking image optimization opportunities..."
find assets/images -type f \( -name "*.jpg" -o -name "*.png" \) -exec ls -lh {} \;

# Check CSS for unused rules (basic check)
echo "🎨 Checking CSS optimization opportunities..."
css_size=$(wc -c < styles/main.css)
echo "Current CSS size: $css_size bytes"

# Remove router.js if it's not being used properly
if [ -f "scripts/router.js" ]; then
    echo "🗑️  Found unused router.js - consider removing or fixing"
fi

echo "✅ Build analysis complete!"
echo ""
echo "📋 Recommendations:"
echo "1. Use the new component system to reduce duplication"
echo "2. Consolidate duplicate sections into reusable components"
echo "3. Consider optimizing images if they're large"
echo "4. Remove or fix unused JavaScript files"
