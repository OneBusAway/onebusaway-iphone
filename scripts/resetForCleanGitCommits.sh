#!/bin/bash
# Clear bundle version
/usr/libexec/PlistBuddy -c "Delete :CFBundleVersion" "$INFOPLIST_FILE"
# Reset bundle identifier to org.onebusaway.iphone.dev
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier org.onebusaway.iphone.dev" "$INFOPLIST_FILE"
