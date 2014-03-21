# OneBusAway for iPhone [![Build Status](https://travis-ci.org/OneBusAway/onebusaway-iphone.png)](https://travis-ci.org/OneBusAway/onebusaway-iphone) [![Stories in Ready](https://githubkanban.herokuapp.com/huboard/OneBusAway/onebusaway-iphone.png)](http://huboard.com/OneBusAway/onebusaway-iphone/board)

## Test latest development release

If you would like to help test the latest development release signup on our [TestFlight page](http://tflig.ht/1ac8oEg).

Have a jailbroken device? [Install the latest commit build](https://github.com/bbodenmiller/onebusaway-iphone-test-releases)

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) and [roadmap](ROADMAP.md).

Our [huboard](http://huboard.com/OneBusAway/onebusaway-iphone/board) lists development priorites and status updates.

### Development environment setup

1. Install Xcode 5 with the iOS 6.0 & 7.0 SDK
2. Install [BBUncrustifyPlugin](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode) to keep your code within our style guidelines
3. `git clone` your fork

You should now be able to build. See our [contributing guidelines](CONTRIBUTING.md) for the specific workflow to add a new feature or bug fix.

### Releasing

* Update the [CHANGELOG](CHANGELOG.md) to reflect the changes in this release
* Update the [version number](https://github.com/OneBusAway/onebusaway-iphone/blob/develop/Info.plist#L20)
* Merge in to `master` branch
* Create AppStore build
* Upload to AppStore, use changelog as release notes
* Create [GitHub release](https://github.com/OneBusAway/onebusaway-iphone/releases) based on changelog
* Upload [dSYM for AppStore build to crashes page](https://testflightapp.com/dashboard/apps/776859/crashes/) (might have to wait until first crash occurs)
