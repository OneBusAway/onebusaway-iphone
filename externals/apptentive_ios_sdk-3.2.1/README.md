# Apptentive iOS SDK

The Apptentive iOS SDK provides a simple and powerful channel to communicate in-app with your customers.

Use Apptentive features to improve your app's App Store ratings, collect and respond to customer feedback, show surveys at specific points within your app, and more.

## Install Guide

Apptentive can be installed manually as an Xcode subproject or via the dependency manager CocoaPods.

The following guides explain the integration process:

 - [Xcode project setup guide](http://www.apptentive.com/docs/ios/setup/xcode/)
 - [CocoaPods installation guide](http://www.apptentive.com/docs/ios/setup/cocoapods)

## Using Apptentive in your App

After integrating the Apptentive SDK into your project, you can [begin using Apptentive features in your app](http://www.apptentive.com/docs/ios/integration/).

You should begin by setting your app's API key, then engaging Apptentive events at various places in your app:

``` objective-c
#import "Apptentive.h"
...
[Apptentive sharedConnection].APIKey = @"<Your API Key>";
...
[[Apptentive sharedConnection] engage:@"event_name" fromViewController:viewController];
```

Or, in Swift:

``` Swift
import Apptentive
...
Apptentive.sharedConnection().APIKey = "<Your API Key>"
...
Apptentive.sharedConnection().engage("event_name", fromViewController: viewController)
```

Later, on your Apptentive dashboard, you will target these events with Apptentive features such as Message Center, Ratings Prompts, and Surveys.

Please see our [iOS integration guide](http://www.apptentive.com/docs/ios/integration/) for more on this subject.

## API Documentation

Please see our docs site for the Apptentive iOS SDK's [API documentation](http://www.apptentive.com/docs/ios/api/Classes/Apptentive.html).

Apptentive's [API changelog](docs/APIChanges.md) is also updated with each release of the SDK.

## Testing Apptentive Features

Please see the [Apptentive testing guide](http://www.apptentive.com/docs/ios/testing/) for directions on how to test that the Rating Prompt, Surveys, and other Apptentive features have been configured correctly.

# Apptentive Example App

To see an example of how the Apptentive iOS SDK can be integrated with your app, take a look at the `iOSExample` app in the `Example` directory in this repository.

The example app shows you how to integrate using CocoaPods, set your API key, engage events, and integrate with Message Center. See the `README.md` file in the `Example` directory for more information.

## Contributing

Our client code is completely [open source](LICENSE.txt), and we welcome contributions to the Apptentive SDK! If you have an improvement or bug fix, please first read our [contribution agreement](CONTRIBUTING.md).

## Reporting Issues

If you experience an issue with the Apptentive SDK, please [open a GitHub issue](https://github.com/apptentive/apptentive-ios/issues?direction=desc&sort=created&state=open).

If the request is urgent, please contact <mailto:support@apptentive.com>.
