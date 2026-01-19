#!/bin/bash

# Firebase App Distribution - iOS
# Usage: ./distribute-ios.sh "Release notes here"

echo "========================================"
echo "Firebase App Distribution - iOS"
echo "========================================"
echo ""

# Check if iOS App ID is set
if [ -z "$IOS_APP_ID" ]; then
    echo "⚠️  iOS App ID not set!"
    echo ""
    echo "To set it, run:"
    echo "  export IOS_APP_ID='1:548250171926:ios:xxxxx'"
    echo ""
    echo "Or edit this script and replace <YOUR_IOS_APP_ID>"
    echo ""
    read -p "Enter iOS App ID now (or press Enter to exit): " IOS_APP_ID
    if [ -z "$IOS_APP_ID" ]; then
        echo "Exiting. Please set IOS_APP_ID and try again."
        exit 1
    fi
fi

echo "Building iOS IPA..."
flutter build ipa --debug

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Build failed! Check errors above."
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""

# Get release notes
if [ -z "$1" ]; then
    read -p "Enter release notes (or press Enter for default): " RELEASE_NOTES
    if [ -z "$RELEASE_NOTES" ]; then
        RELEASE_NOTES="iOS build - $(date '+%Y-%m-%d %H:%M:%S')"
    fi
else
    RELEASE_NOTES="$1"
fi

echo ""
echo "Distributing to Firebase App Distribution..."
echo "Release notes: $RELEASE_NOTES"
echo ""

firebase appdistribution:distribute build/ios/ipa/knot.ipa \
  --project knot-29668 \
  --app "$IOS_APP_ID" \
  --groups "beta-testers" \
  --release-notes "$RELEASE_NOTES"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Distribution failed!"
    echo ""
    echo "Make sure:"
    echo "1. Firebase CLI is installed: npm install -g firebase-tools"
    echo "2. You're logged in: firebase login"
    echo "3. iOS App ID is correct: $IOS_APP_ID"
    echo "4. Tester group 'beta-testers' exists in Firebase Console"
    exit 1
fi

echo ""
echo "========================================"
echo "✅ Distribution successful!"
echo "========================================"
echo "iOS testers will receive an email with download link."
echo ""
echo "View release: https://console.firebase.google.com/project/knot-29668/appdistribution"
echo ""
