# OneBusAway for iPhone [![Build Status](https://img.shields.io/travis/OneBusAway/onebusaway-iphone.svg)](https://travis-ci.org/OneBusAway/onebusaway-iphone) [![codebeat badge](https://codebeat.co/badges/080b2d57-c69b-466e-be49-3b5b7e02c8d8)](https://codebeat.co/projects/github-com-onebusaway-onebusaway-iphone) [![Join the OneBusAway chat on Slack](https://onebusaway.herokuapp.com/badge.svg)](https://onebusaway.herokuapp.com/)

## Test latest development release

If you would like to help test the latest development release, email us at [iphone-app@onebusaway.org](mailto:iphone-app@onebusaway.org) to be added to our TestFlight Beta testing group.

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) and [roadmap](https://github.com/OneBusAway/onebusaway-iphone/wiki/Roadmap).

### Picking an appropriate first-time issue

You are welcome to work on any bug or feature you would like, but we know that getting started in a new codebase can be intimidating. To that end, we recommend that you take a look at issues labeled as [Your First PR](https://github.com/OneBusAway/onebusaway-iphone/labels/Your%20First%20PR). These issues are relatively small and self-contained, and should be perfect for anyone who is interested in getting their feet wet with the OneBusAway codebase.

(h/t to Microsoft's [ChakraCore](https://github.com/Microsoft/ChakraCore) project for the idea of the first PR)

### Development environment setup

1. Install Xcode 8.0.x
2. `git clone` your fork
3. `(sudo) gem install cocoapods --pre` (We require Cocoapods 1.1.0.rc.1 or higher!)
4. `pod install`
5. Open `org.onebusaway.iphone.xcworkspace`

You should now be able to build. See our [contributing guidelines](CONTRIBUTING.md) for the specific workflow to add a new feature or bug fix.

### Releasing

* Update the [CHANGELOG](CHANGELOG.md) to reflect the changes in this release
* Update the [version number](https://github.com/OneBusAway/onebusaway-iphone/blob/develop/Info.plist#L20)
* Merge in to `master` branch
* Create AppStore build
* Upload to AppStore, use changelog as release notes
* Create [GitHub release](https://github.com/OneBusAway/onebusaway-iphone/releases) based on changelog
