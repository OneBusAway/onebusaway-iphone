# OneBusAway for iPhone
[![Build Status](https://img.shields.io/travis/OneBusAway/onebusaway-iphone.svg)](https://travis-ci.org/OneBusAway/onebusaway-iphone)
[![Join the chat at https://gitter.im/OneBusAway/onebusaway-iphone](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/OneBusAway/onebusaway-iphone?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Visit our IRC channel](http://img.shields.io/badge/IRC-%23OneBusAway-green.svg)](https://kiwiirc.com/client/irc.freenode.net/?nick=obauser|?&theme=basic#OneBusAway)  [![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=5632a0b9f7df810100e4eb40&branch=develop&build=latest)](https://dashboard.buddybuild.com/apps/5632a0b9f7df810100e4eb40/build/latest)

## Test latest development release

If you would like to help test the latest development release, email us at [iphone-app@onebusaway.org](mailto:iphone-app@onebusaway.org) to be added to our TestFlight Beta testing group.

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) and [roadmap](ROADMAP.md).

Our [huboard](https://huboard.com/OneBusAway/onebusaway-iphone) lists development priorites and status updates.

### Development environment setup

1. Install Xcode 6 with the iOS 8.x SDK
2. Install [BBUncrustifyPlugin](https://github.com/benoitsan/BBUncrustifyPlugin-Xcode#installation) to keep your code within our style guidelines
3. `git clone` your fork
4. Open `org.onebusaway.iphone.xcworkspace`

You should now be able to build. See our [contributing guidelines](CONTRIBUTING.md) for the specific workflow to add a new feature or bug fix.

### Releasing

* Update the [CHANGELOG](CHANGELOG.md) to reflect the changes in this release
* Update the [version number](https://github.com/OneBusAway/onebusaway-iphone/blob/develop/Info.plist#L20)
* Merge in to `master` branch
* Create AppStore build
* Upload to AppStore, use changelog as release notes
* Create [GitHub release](https://github.com/OneBusAway/onebusaway-iphone/releases) based on changelog
