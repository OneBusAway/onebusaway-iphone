# OneBusAway for iPhone [![Build Status](https://img.shields.io/travis/OneBusAway/onebusaway-iphone.svg)](https://travis-ci.org/OneBusAway/onebusaway-iphone) [![Join the OneBusAway chat on Slack](https://onebusaway.herokuapp.com/badge.svg)](https://onebusaway.herokuapp.com/)

## Test latest development release

If you would like to help test the latest development release, email us at [iphone-app@onebusaway.org](mailto:iphone-app@onebusaway.org) to be added to our TestFlight Beta testing group.

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) and [roadmap](https://github.com/OneBusAway/onebusaway-iphone/wiki/Roadmap).

Our [huboard](https://huboard.com/OneBusAway/onebusaway-iphone) lists development priorites and status updates.

### Development environment setup

1. Install Xcode 7.x
2. `git clone` your fork
3. `(sudo) gem install cocoapods`
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
