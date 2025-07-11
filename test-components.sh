#!/bin/bash

# Component Test Script
# Verifies that all HTML files are using the component system correctly

echo "🧪 Testing Component System Implementation..."
echo ""

# Check if component files exist
echo "📁 Checking component files..."
for component in header footer contact music; do
    if [ -f "components/${component}.html" ]; then
        echo "✅ ${component}.html exists"
    else
        echo "❌ ${component}.html missing"
    fi
done

echo ""

# Check if main HTML files use placeholder divs
echo "🔍 Checking for component placeholders in HTML files..."
for file in *.html; do
    if [ -f "$file" ]; then
        echo "Checking $file:"
        
        # Check for header placeholder
        if grep -q "header-placeholder" "$file"; then
            echo "  ✅ Header component placeholder found"
        else
            echo "  ❌ Header component placeholder missing"
        fi
        
        # Check for footer placeholder
        if grep -q "footer-placeholder" "$file"; then
            echo "  ✅ Footer component placeholder found"
        else
            echo "  ❌ Footer component placeholder missing"
        fi
        
        # Check for main.js script
        if grep -q "scripts/main.js" "$file"; then
            echo "  ✅ main.js script included"
        else
            echo "  ❌ main.js script missing"
        fi
        
        echo ""
    fi
done

# Check experience files
echo "🏢 Checking experience files..."
for file in experience/*.html; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "Checking experience/$filename:"
        
        if grep -q "header-placeholder" "$file"; then
            echo "  ✅ Header component placeholder found"
        else
            echo "  ❌ Header component placeholder missing"
        fi
        
        if grep -q "../scripts/main.js" "$file"; then
            echo "  ✅ main.js script included with correct path"
        else
            echo "  ❌ main.js script missing or incorrect path"
        fi
        
        echo ""
    fi
done

echo "🎯 Component System Test Complete!"
