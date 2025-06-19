#
//  build.sh
//  NSDK-Commerce
//
//  Created by Raj on 18/06/25.
//

#!/bin/bash

set -e

SCHEME="NSDK-Commerce"
CONFIGURATION="Release"
PROJECT="NSDK-Commerce.xcodeproj"
FRAMEWORK_NAME="NSDK_Commerce"

# Output Paths
BUILD_DIR="./build"
DEVICE_ARCHIVE="${BUILD_DIR}/iphoneos.xcarchive"
SIMULATOR_ARCHIVE="${BUILD_DIR}/iphonesimulator.xcarchive"
XCFRAMEWORK_DIR="${BUILD_DIR}/${SCHEME}.xcframework"

# Cleanup
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "📦 Archiving for Device..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -archivePath "$DEVICE_ARCHIVE" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ENABLE_BITCODE=NO

echo "🧪 Archiving for Simulator..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$SIMULATOR_ARCHIVE" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ENABLE_BITCODE=NO

echo "🎁 Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "$DEVICE_ARCHIVE/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -framework "$SIMULATOR_ARCHIVE/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -output "$XCFRAMEWORK_DIR"


echo "✅ XCFramework created at: $XCFRAMEWORK_DIR"
