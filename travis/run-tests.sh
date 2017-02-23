#!/bin/sh
set -ex
# show available schemes
xcodebuild -list -project ./mPowerSDK.xcodeproj
# run on pull request
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  fastlane test scheme:"mPowerSDK"
  exit $?
fi
