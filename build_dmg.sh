#!/bin/bash
set -e

# Build script for SaneSideButtons
# This script builds the app and creates a DMG for distribution

echo "🔨 Building SaneSideButtons..."

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf build
rm -f SaneSideButtons*.dmg

# Build the app
echo "Building app with Xcode..."
xcodebuild \
  -project SaneSideButtons.xcodeproj \
  -scheme SaneSideButtons \
  -configuration Release \
  -derivedDataPath build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  clean build

# Check if build succeeded
if [ ! -d "build/Build/Products/Release/SaneSideButtons.app" ]; then
  echo "❌ Build failed - app not found"
  exit 1
fi

echo "✅ Build successful!"

# Get version info
VERSION=$(defaults read "$(pwd)/build/Build/Products/Release/SaneSideButtons.app/Contents/Info.plist" CFBundleShortVersionString)
BUILD=$(defaults read "$(pwd)/build/Build/Products/Release/SaneSideButtons.app/Contents/Info.plist" CFBundleVersion)
echo "📦 Version: $VERSION (build $BUILD)"

# Create DMG
echo "Creating DMG..."

# Create temp folder for DMG contents
mkdir -p dmg_temp
cp -r build/Build/Products/Release/SaneSideButtons.app dmg_temp/

# Check if create-dmg is installed
if command -v create-dmg &> /dev/null; then
  echo "Using create-dmg..."
  create-dmg \
    --volname "SaneSideButtons" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "SaneSideButtons.app" 175 190 \
    --hide-extension "SaneSideButtons.app" \
    --app-drop-link 425 190 \
    --no-internet-enable \
    "SaneSideButtons-v${VERSION}-build${BUILD}.dmg" \
    "dmg_temp/" || \
  hdiutil create -volname "SaneSideButtons" -srcfolder dmg_temp -ov -format UDZO "SaneSideButtons-v${VERSION}-build${BUILD}.dmg"
else
  echo "create-dmg not found, using hdiutil..."
  echo "Tip: Install create-dmg for prettier DMGs: brew install create-dmg"
  hdiutil create -volname "SaneSideButtons" -srcfolder dmg_temp -ov -format UDZO "SaneSideButtons-v${VERSION}-build${BUILD}.dmg"
fi

# Also create a simple "latest" version
cp "SaneSideButtons-v${VERSION}-build${BUILD}.dmg" "SaneSideButtons.dmg"

# Cleanup
rm -rf dmg_temp

echo "✅ DMG created successfully!"
echo "📦 Output files:"
ls -lh SaneSideButtons*.dmg

# Calculate checksum
echo ""
echo "🔐 SHA-256 Checksum:"
shasum -a 256 "SaneSideButtons-v${VERSION}-build${BUILD}.dmg"

echo ""
echo "🎉 Done! You can now install from: SaneSideButtons.dmg"
