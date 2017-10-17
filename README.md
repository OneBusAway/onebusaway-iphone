# OneBusAway for iPhone [![Build Status](https://img.shields.io/travis/OneBusAway/onebusaway-iphone.svg)](https://travis-ci.org/OneBusAway/onebusaway-iphone) [![codebeat badge](https://codebeat.co/badges/080b2d57-c69b-466e-be49-3b5b7e02c8d8)](https://codebeat.co/projects/github-com-onebusaway-onebusaway-iphone) [![Join the OneBusAway chat on Slack](https://onebusaway.herokuapp.com/badge.svg)](https://onebusaway.herokuapp.com/)

## Start Here

1. [Come join our Slack channel](https://onebusaway.herokuapp.com/) to say hi and let us know what you're interested in working on.
2. We maintain a set of tasks that we think would be good choices for people interested in working on OneBusAway. Learn more about them here: [Picking an appropriate first time issue](#picking-an-appropriate-first-time-issue)
3. This project adheres to the [Open Code of Conduct](http://todogroup.org/opencodeofconduct/#OneBusAway/conduct@onebusaway.org). By participating, you are expected to honor this code.
4. Now, [learn about setting up your development environment](#development-environment-setup).

---------

## Test latest development release

If you would like to help test the latest development release, email us at [iphone-app@onebusaway.org](mailto:iphone-app@onebusaway.org) to be added to our TestFlight Beta testing group.

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) and [upcoming milestones](https://github.com/OneBusAway/onebusaway-iphone/milestones). This project adheres to the [Open Code of Conduct](http://todogroup.org/opencodeofconduct/#OneBusAway/conduct@onebusaway.org). By participating, you are expected to honor this code.

### Individual Contributor License Agreement (ICLA)
To ensure that the app source code remains fully open-source under a common license, we require that contributors sign an electronic ICLA before contributions can be merged.  When you submit a pull request, you'll be prompted by the [CLA Assistant](https://cla-assistant.io/) to sign the ICLA.

### Picking an appropriate first-time issue

You are welcome to work on any bug or feature you would like, but we know that getting started in a new codebase can be intimidating. To that end, we recommend that you take a look at issues labeled as [Your First PR](https://github.com/OneBusAway/onebusaway-iphone/labels/Your%20First%20PR). These issues are relatively small and self-contained, and should be perfect for anyone who is interested in getting their feet wet with the OneBusAway codebase.

(h/t to Microsoft's [ChakraCore](https://github.com/Microsoft/ChakraCore) project for the idea of the first PR)

### Development environment setup

1. Install the latest released version of Xcode 9.x from the Mac App Store
2. `git clone` your fork
3. [Install Carthage](https://github.com/Carthage/Carthage#installing-carthage)
4. `open org.onebusaway.iphone.xcodeproj`

You should now be able to build. See our [contributing guidelines](CONTRIBUTING.md) for the specific workflow to add a new feature or bug fix.

### Localization Notes

It is vital that any user-facing strings in this project are localized. If your changes reside within the OBA app itself, you must use the `NSLocalizedString` macro to wrap your localizable strings. If your changes reside within OBAKit, you must make sure that you import the `OBAMacros.h` header file and use the `OBALocalized` macro to localize your strings.

#### Localizers: README

If you are localizing the app: a) thank you so much, and b) you must supply the `-s` option to `genstrings` for OBAKit's custom localization macro, like so:

```
genstrings -s OBALocalized
```
