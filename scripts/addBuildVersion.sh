#!/bin/bash
# Get current git commit short SHA
gitCommitSHA=$(git rev-parse --short HEAD)
# Check if the git working copy is dirty
if test -n "$(git status --porcelain)"
then
# Append a plus character to the git commit short SHA to indicate dirty changes in build
gitCommitSHA+="+"
fi
# Set bundle build version to current git commit short SHA with dirty indicator
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $gitCommitSHA" "$INFOPLIST_FILE"
