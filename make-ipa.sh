#!/bin/bash
# Packages the app as SleepOnIt.ipa so AltStore / SideStore can install and auto-refresh it.
# Run this AFTER you've picked your Team in Xcode and run the app on your phone once.
set -e
cd "$(dirname "$0")"

echo "Building… (takes a minute)"
xcodebuild \
  -project SleepOnIt.xcodeproj \
  -scheme SleepOnIt \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build \
  -allowProvisioningUpdates \
  -quiet \
  build

rm -rf .build/ipa
mkdir -p .build/ipa/Payload
cp -R .build/Build/Products/Release-iphoneos/SleepOnIt.app .build/ipa/Payload/
(cd .build/ipa && zip -qr ../../SleepOnIt.ipa Payload)

echo ""
echo "Created SleepOnIt.ipa in this folder."
echo "AirDrop or iCloud-Drive it to your phone, then open it with AltStore/SideStore (or use their + button)."
