# OneBusAway for iPhone [![Build Status](https://travis-ci.org/OneBusAway/onebusaway-iphone.png)](https://travis-ci.org/OneBusAway/onebusaway-iphone) [![Stories in Ready](https://githubkanban.herokuapp.com/huboard/OneBusAway/onebusaway-iphone.png)](http://huboard.com/OneBusAway/onebusaway-iphone/board)

## Test latest development release

If you would like to help test the latest development release signup on our [TestFlight page](http://tflig.ht/1ac8oEg).

Have a jailbroken device? [Install the latest commit build](https://github.com/bbodenmiller/onebusaway-iphone-test-releases)

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) and [roadmap](ROADMAP.md).

Our [huboard](http://huboard.com/OneBusAway/onebusaway-iphone/board) lists development priorites and status updates.

## Build instructions

* Clone the repository.
* Open the `org.onebusaway.iphone.xcodeproj` project file.

You should now be able to build.

### Requirements

Development: Xcode 4.5/iOS 6.0 SDK

Runtime: iOS 5.1 or higher

### Releasing

* Update the [CHANGELOG](CHANGELOG.md) to reflect the changes in this release
* Update the [version number](https://github.com/OneBusAway/onebusaway-iphone/blob/develop/Info.plist#L20)
* Merge in to `master` branch
* Create AppStore build
* Upload build to [TestFlight](http://testflightapp.com) and dSYM to crashes section for build
* Upload to AppStore, use changelog as release notes
* Create [GitHub release](https://github.com/OneBusAway/onebusaway-iphone/releases) based on changelog
