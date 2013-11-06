#!/bin/bash
# Check if current build configuration is for App Store release
if [ "$CONFIGURATION" == "AppStoreDistribution" ]
then
	# Set bundle identifier to org.onebusaway.iphone for App Store release
	echo "#define BUNDLE_IDENTIFIER org.onebusaway.iphone" >> $PROJECT_TEMP_DIR/infoplist.prefix
else
	echo "#define BUNDLE_IDENTIFIER org.onebusaway.iphone.dev" >> $PROJECT_TEMP_DIR/infoplist.prefix
fi
