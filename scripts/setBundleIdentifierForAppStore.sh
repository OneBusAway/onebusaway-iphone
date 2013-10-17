#!/bin/bash
# Check if current build configuration is AppStoreDistribution
if [ "$CONFIGURATION" == "AppStoreDistribution" ]
then
# Set bundle identifier to org.onebusaway.iphone for App Store release
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier org.onebusaway.iphone" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
fi
