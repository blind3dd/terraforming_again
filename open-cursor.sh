#!/bin/bash

# Simple Cursor Launcher
# This script opens Cursor with the current directory

echo "🚀 Opening Cursor..."

# Check if Cursor is installed
if [ -d "/Applications/Cursor.app" ]; then
    echo "Cursor found in Applications"
    open -a Cursor .
else
    echo "Cursor not found in Applications"
    echo "   Please install Cursor from https://cursor.sh"
    exit 1
fi

echo "Cursor should now be opening..."
echo ""
echo "After Cursor opens:"
echo "1. Open a Go file (e.g., applications/go-mysql-api/conff/config.go)"
echo "2. Open a Terraform file (e.g., infrastructure/terraform/syntax-test.tf)"
echo "3. Check if syntax highlighting works"
echo ""
echo " If syntax highlighting doesn't work:"
echo "1. Check Output panel → 'Go' and 'Terraform' for errors"
echo "2. Restart language servers in Command Palette"
echo "3. Reload window: Command Palette → 'Developer: Reload Window'"

