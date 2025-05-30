#!/bin/bash

echo "Creating Admin Account for Medical App Dashboard"
echo "================================================"
echo

# Check if we're in the scripts directory
if [ -f "create_admin.dart" ]; then
    echo "Running from scripts directory..."
    dart pub get
    dart run create_admin.dart
else
    echo "Running from project root..."
    dart run scripts/create_admin.dart
fi

echo
echo "Script completed." 