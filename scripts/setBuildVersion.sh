#!/bin/bash
# Use git commit short SHA for Debug/AdHocDistribution configuration (e.g. TestFlight)
if [ "$CONFIGURATION" == "Debug" -o "$CONFIGURATION" == "AdHocDistribution" ]
then
    # Get current git commit short SHA
    gitCommitSHA=$(git rev-parse --short HEAD)
    # Check if the git working copy is dirty
    if [ -n "$(git status --porcelain)" ]
    then
        # Append a plus character to the git commit short SHA to indicate dirty changes in build
        gitCommitSHA+="+"
    fi
fi

# Use git commit count for Master branch and AppStoreDistribution configuration (e.g. App Store release)
currentGitBranchName=$(git rev-parse --abbrev-ref HEAD)
if [ "$currentGitBranchName" == "master" -a "$CONFIGURATION" == "AppStoreDistribution" ]
then
    # Get current git commit count
    gitCommitSHA=$(git rev-list HEAD | wc -l | tr -d ' ')
fi

#
if [ -n "$gitCommitSHA" ]
then
    # Set bundle build version
    echo "#define GIT_COMMIT_SHA $gitCommitSHA" >> $PROJECT_TEMP_DIR/infoplist.prefix
    # Tell Xcode to preprocess Info.plist
    touch $PROJECT_DIR/Info.plist
fi
