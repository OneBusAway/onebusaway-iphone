# OneBusAway for iPhone [![Build Status](https://travis-ci.org/OneBusAway/onebusaway-iphone.png)](https://travis-ci.org/OneBusAway/onebusaway-iphone) [![Stories in Ready](https://githubkanban.herokuapp.com/huboard/OneBusAway/onebusaway-iphone.png)](http://huboard.com/OneBusAway/onebusaway-iphone/board)

## Test latest development release

If you would like to help test the latest development release signup on our [TestFlight page](http://tflig.ht/1ac8oEg).

Have a jailbroken device? [Install the latest commit build](https://github.com/bbodenmiller/onebusaway-iphone-test-releases)

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) and [roadmap](ROADMAP.md).

Our [huboard](http://huboard.com/OneBusAway/onebusaway-iphone/board) lists development priorites and status updates.

As mentioned in the Contributing Guidelines, we require that all submitted code follows the New York Times style guide.
One of the easiest ways to make sure code is compliant is to run Uncrustify on any modified or created files.
The easiest way to do that is to install [BBUncrustifyPlugin](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode),
which will automatically use the uncrustify config included in the OBA repo, and allows for quick cleanup of
selected lines, the active file, or a selection of files from the XCode Edit menu.

## Build instructions

* Clone the repository.
* Open the `org.onebusaway.iphone.xcodeproj` project file.

You should now be able to build.

### Requirements

Development: Xcode 5/iOS 6.0 & 7.0 SDK

Runtime: iOS 5.1 or higher

### Releasing

* Update the [CHANGELOG](CHANGELOG.md) to reflect the changes in this release
* Update the [version number](https://github.com/OneBusAway/onebusaway-iphone/blob/develop/Info.plist#L20)
* Merge in to `master` branch
* Create AppStore build
* Upload to AppStore, use changelog as release notes
* Create [GitHub release](https://github.com/OneBusAway/onebusaway-iphone/releases) based on changelog
* Upload [dSYM for AppStore build to crashes page](https://testflightapp.com/dashboard/apps/776859/crashes/) (might have to wait until first crash occurs)
