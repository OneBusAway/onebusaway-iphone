#!/bin/sh
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  echo "\nThis is a pull request. No deployment will be done."
  exit 0
fi
#if [[ "$TRAVIS_BRANCH" != "master" ]]; then
  echo "\nTesting on $TRAVIS_BRANCH branch."
  #exit 0
#fi

#echo "\n********************"
#echo "*  Zipping files   *"
#echo "********************"
#if [[ zip -r -9 -q "$HOME/Library/Developer/Xcode/Archives/$APPNAME.zip" "$HOME/Library/Developer/Xcode/Archives/" -ne 0 ]]; then
#  exit -1
#fi

ARCHIVE_DIR=`find $HOME/Library/Developer/Xcode/Archives -name "$APPNAME.app" | head -1`
#echo $ARCHIVE_DIR

COMMIT_MSG=`git log -1 --pretty=%B`
#echo $COMMIT_MSG

echo "\n********************"
echo "*  Add deploy key  *"
echo "********************"
git clone $DEPLOY_READONLY_REPO
cd onebusaway-iphone-test-releases
eval `ssh-agent -s`
chmod 600 id_rsa # this key should have push access
ssh-add id_rsa
git remote add deploy $DEPLOY_SSH_REPO

echo "\n********************"
echo "*    Copy Files    *"
echo "********************"
git branch $TRAVIS_BRANCH
git checkout $TRAVIS_BRANCH
#git fetch deploy
#git merge deploy/$TRAVIS_BRANCH
git pull deploy $TRAVIS_BRANCH -m "pull"
echo "cp -r \"$ARCHIVE_DIR\" ."
cp -R "$ARCHIVE_DIR" .

#so it will work on jailbroken devices
echo "\n********************"
echo "*   Fake signing   *"
echo "********************"
if [[ ! -f ldid ]]; then
  curl -o ldid https://networkpx.googlecode.com/files/ldid
fi
chmod +x ./ldid
chmod +x $APPNAME.app/$APPNAME
./ldid -S $APPNAME.app/$APPNAME
#lipo -info OneBusAway
#otool -L OneBusAway
#file OneBusAway

echo "\n********************"
echo "*   Deploy to GH   *"
echo "********************"
git add -A
git commit -m "$COMMIT_MSG"
git config --global push.default simple #to remove some special warning message about git 2.0 changes
git fetch
git status
git remote -v
git show remote origin
git show remote deploy
git pull deploy $TRAVIS_BRANCH
#todo: only push if newer build hasn't already pushed: see http://madebynathan.com/2012/01/31/travis-ci-status-in-shell-prompt/ & https://github.com/travis-ci/travis#installation & https://github.com/rcrowley/json.sh and https://api.travis-ci.org/repositories/OneBusAway/onebusaway-iphone.json
git push deploy $TRAVIS_BRANCH #if another CI build pushes at the same time issues may occur

RC=$?
echo "git exit code: $RC"
if [[ $RC -ne "0" ]]; then
  echo "error hit"
  exit -1
fi

if [[ $RC -ne "1" ]]; then
  echo "no error"
fi

exit 0
