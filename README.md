# OneBusAway for iPhone
[![Build Status](https://travis-ci.org/OneBusAway/onebusaway-iphone.png)](https://travis-ci.org/OneBusAway/onebusaway-iphone)

## Test latest development release

If you would like to help test the latest development builds signup on our [TestFlight page](http://tflig.ht/1ac8oEg).

## Build instructions

* Clone the repository.
* Execute the following Git commands to pull in external project dependencies:

~~~
git submodule init
git submodule update
~~~

* Open the `org.onebusaway.iphone.xcodeproj` project file.

You should now be able to build.

### Requirements

Development: Xcode 4.5/iOS 6.0 SDK

Runtime: iOS 5.1 or higher

### Releasing

When uploading to app store rename `org.onebusaway.iphone-debug` to `org.onebusaway.iphone` in `Info.plist`

## Contributing

See our [contributing guidelines](CONTRIBUTING.md) and [roadmap](ROADMAP.md).
