#!/bin/sh

XCODE_MAJOR_VERSION=`xcodebuild -version | awk 'NR == 1 {print substr($2,1,1)}'`
if [ "$XCODE_MAJOR_VERSION" -ge "5" ]; then
        echo "Xcode 5 already installed."
        exit 0
fi

echo "Installing Xcode 5."

#todo: check if downloaded file, else retry

#uninstall xcode 4
sudo rm -R /Applications/Xcode.app

#install xcode
curl -o x5gm.dmg https://copy.com/8yyq7U7Bl0sVEIRe/x5gm.dmg #download installer
hdiutil attach x5gm.dmg #mount
sudo cp -R "/Volumes/Xcode/Xcode.app" /Applications #copy
rm x5gm.dmg #rm installer

#agree to xcode license
sudo -E scripts/travis/accept_license.sh

#print ver
xcodebuild -version -sdk