# OneBusAway for iPhone
[![Build Status](https://travis-ci.org/OneBusAway/onebusaway-iphone.png)](https://travis-ci.org/OneBusAway/onebusaway-iphone)

## Test latest development release

If you would like to help test the latest development release signup on our [TestFlight page](http://tflig.ht/1ac8oEg).

Have a jailbroken device? [Install the latest commit build](https://github.com/bbodenmiller/onebusaway-iphone-test-releases)

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) and [roadmap](ROADMAP.md).

## Build instructions

* Clone the repository.
* Open the `org.onebusaway.iphone.xcodeproj` project file.

You should now be able to build.

### Requirements

Development: Xcode 4.5/iOS 6.0 SDK

Runtime: iOS 5.1 or higher

### Releasing

* Update the [CHANGELOG](CHANGELOG.md) to reflect the changes in this release
* Create [GitHub release](https://github.com/OneBusAway/onebusaway-iphone/releases) based on changelog
* Use changelog as App Store release notes
* When uploading to App Store rename `org.onebusaway.iphone-debug` to `org.onebusaway.iphone` in `Info.plist`
