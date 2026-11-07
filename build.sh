#!/usr/bin/env bash
# Local build (on a Mac with Xcode + XcodeGen): produces ScoutCam.ipa (unsigned)
set -e
cd "$(dirname "$0")"
xcodegen generate
xcodebuild -project ScoutCam.xcodeproj -scheme ScoutCam -sdk iphoneos -configuration Release \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build
rm -rf Payload ScoutCam.ipa
mkdir -p Payload
cp -r build/Build/Products/Release-iphoneos/ScoutCam.app Payload/
zip -qry ScoutCam.ipa Payload
echo "Built ScoutCam.ipa"
