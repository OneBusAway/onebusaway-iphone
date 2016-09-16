2016-08-09 frankus v3.2.1
-------------------------
Version 3.2.1 improves stability and reliability and fixes several warnings when
building with Xcode 8.0 beta. This release is intended to be compatible with
iOS 10. In addition, the Demo app has been removed from the repository. 

2016-07-08 frankus v3.2.0
-------------------------
Version 3.2.0 adds a range question type in order to support NPS-style survey
questions. It also improves RTL language support and accessibility and includes
several bug fixes. Logging now respects preprocessor macros when integrating
via CocoaPods.

2016-06-21 frankus v3.1.1
-------------------------
Version 3.1.1 fixes an issue where surveys could crash if the Apptentive
singleton was instantiated after the app became active. It also improves the
scrolling behavior in surveys.

2016-06-08 frankus v3.1.0
-------------------------
Version 3.1.0 adds the ability to include a freeform "Other" choice for single-
and multiple-selection question types in surveys. The FeedbackDemo app has been
replaced by separate Demo and Example apps. See the README for each app for
details.

2016-04-26 frankus v3.0.0
-------------------------
Version 3.0.0 introduces a redesigned survey UI and enhanced styling capability.
The ATConnect class has been renamed to Apptentive, and several enums and string
constants have also been changed. See the migration guide in the docs directory
for more information.

2016-03-09 frankus v2.1.3
-------------------------
Version 2.1.3 contains a fix for flagging automated messages as such. It also
fixes an issue where the post-survey HUD view was rotating incorrectly on iOS 9
devices.

2016-02-05 frankus v2.1.2
-------------------------
Version 2.1.2 contains a fix for a namespace collision with a system
framework. It also fixes a race condition in the deallocation of Message Center.
It sets the module name for CocoaPods users to simplify integration
with Swift projects.

2016-01-14 frankus v2.1.1
-------------------------
Version 2.1.1 contains bug fixes and fixes several deprecation warnings for
iOS 8 deployment targets. The code formatting has been made more consistent.

2015-12-09 frankus v2.1.0
--------------------------------
Version 2.1 contains several major features:

- Restores the ability to send images in Message Center.
- Adds remote notification background fetch capability for new messages in Message Center.
- Adds new strongly-typed setters for custom person and device data.
- Includes numerous bug fixes and improvements.

2015-10-27 frankus v2.0.5
--------------------------------

Version 2.0.5 adds missing keys in ApptentiveResource.bundle's Info.plist file for CocoaPods.

2015-10-26 frankus v2.0.4
--------------------------------

Version 2.0.4 is a small bugfix update, including missing keys in ApptentiveResource.bundle's Info.plist file and localization fixes for Chinese and Portuguese.

2015-10-14 pkamb, frankus v2.0.3
--------------------------------

Version 2.0.3 is a small bugfix update, including fixes for a memory leak and an issue displaying image messages in the 2.0 Message Center.

2015-09-08 pkamb, frankus v2.0.2
--------------------------------

Version 2.0.2 fixes several bugs a bug where the bar tint color of Message Center was not overridable using UIAppearance. As a side effect, the default barTintColor of the survey UI now adopts the Apptentive Default white. In addition, the tintColor property has been deprecated in favor of using UIAppearance. See the iOS Customization Guide for more information.

This version fixes a bug that was not allowing in-app notification banners to be enabled for new messages in Message Center.

The Message Center UI also contains a number of small usability improvements.

2015-09-08 pkamb, frankus v2.0.1
--------------------------------

Version 2.0.1 contains fixes for our CocoaPods release, which was not working correctly with 2.0.0.

Please use 2.0.1 with CocoaPods for the new Message Center and ARC changes. Non-CocoaPods builds can continue to use 2.0.0, or upgrade to 2.0.1.

2015-09-02 pkamb, frankus v2.0.0
--------------------------------

The 2.0.0 release includes major improvements to the Apptentive Message Center, fixes for iOS 9, conversion of the project to ARC, and many other changes.

The Message Center UI has been completely redesigned. All Message Center text now comes from your web dashboard, which allows for greater customization.

Many fixes have been made in preparation for iOS 9.

The Apptentive SDK has been converted to Automatic Reference Counting (ARC).

Push Notifications can now be added directly through Apptentive, with no need to integrate with a 3rd-party service. The API for adding Push Notifications has also been updated.

Localization has been added for Polish.

Many older API methods have been updated or removed. Please see the "Migrating to 2.0.0" document in this repository for details.

2015-04-23 pkamb, frankus v1.7.3
--------------------------------

The 1.7.3 release contains a variety of small enhancements.

The Feedback Dialog has received a number of UI improvements. Upgrade Messages are now displayed in full screen, and a rotation bug has been fixed. Warnings introduced by Xcode 6.3 have been fixed.

Localization files have been added for Arabic, Brazilian Portuguese, French Canadian, Korean, Spanish (Spain), and Turkish.

Finally, the Feedback Demo example application now allows you to easily select and display any interaction created on your Apptentive account. This allows for easy testing of any given interaction, such as a Survey or Upgrade Message, without needing to first engage the required events or satisfy any time limits.

2015-03-23 pkamb, wooster v1.7.2
--------------------------------

The 1.7.2 release contains a fix for multithreaded execution of `engage:` calls. Engaging events from a background thread had the possibility to cause Core Data issues. In 1.7.2, all `engage:` calls are made on the Main Thread.

2015-02-10 pkamb v1.7.1
--------------------------------

The 1.7.1 release contains support for the new "Notes" feature. Use a Note interaction to send an alert with a link or a Survey to people using your app.

Other improvements include fixing an issue where the "View Messages" button could be shown when Message Center was disabled.

The Notes feature is currently in Beta. If you would like to create Notes via your Apptentive dashboard, please contact us: support@apptentive.com

2014-11-20 pkamb v1.6.1
--------------------------------
The 1.6.1 release contains an improved FeedbackDemo project for easily testing your Apptentive events and interactions. Simply input your API Key and custom events in the `defines.h` file, then tap the respective buttons in the demo app to engage those events.

This release also fixes the default message text in the Ratings Prompt, which for some languages may have referenced Message Center when Message Center was disabled.

We have also fixed an issue where some messages were not sorted correctly in Message Center, and toned down Apptentive logging in Release builds.

2014-10-20 pkamb v1.6.0
--------------------------------
The 1.6.0 release adds the method `willShowInteractionForEvent:`, which returns YES if engaging the given event will cause an Interaction to be shown.

For example, `willShowInteractionForEvent:` returns YES if a survey is ready to be shown the next time you engage your survey-targeted event. You can thus use this method to hide a "Show Survey" button in your app if there is no survey to take.

We have also fixed an issue with adding photos to Message Center on iOS 8 iPads, as well as some Xcode 6 static analyzer warnings.

Finally, we have added xib-based Launch Images to the Apptentive demo app. This fixes an issue when presenting Message Center from landscape on iPhone 6 and 6 Plus devices. If you are experiencing the same problem, you will most likely need to add Launch Images for the new iPhone screen sizes to your parent app.

2014-09-26 pkamb v1.5.8
--------------------------------
This release adds a number of fixes for the landscape presentation of Message Center in iOS 8. If you discover other iOS 8 issues in your app, please contact us!

We have also fixed an issue related to targeting interactions based upon custom data. If you are targeting Surveys or Rating Prompts to show only to people with certain `device` or `person` custom data attributes, you will need to update to this version of the SDK.

2014-09-12 pkamb v1.5.7
--------------------------------

This release adds a number of small fixes for Xcode 6 and iOS 8. We've updated the project to use Xcode 6's default settings, and fixed a number of warnings that surfaced in Xcode 6.

We have also added an `ATSurveyShownNotification` notification when a survey is shown.

We are now immediately updating new Push Notification integrations to the server, which will make for easier testing of new integrations. These were previously batched with device updates.

This release fixes a malformed image that caused a `pngcrush` error in Xcode CI builds.

Finally, we removed a debug background color that slipped into the iOS 6 Message Center's textfield.

2014-08-24 pkamb v1.5.6
--------------------------------

This release adds initial iOS 8 support to the Apptentive SDK.

Specifically, an issue has been fixed where Message Center messages are not displayed in iOS 8. An iPad layout issue has also been fixed.

We will continue to add fixes as we test Apptentive with the latest iOS 8 beta releases. If you identify iOS 8 issues in the SDK, please contact us by opening a [GitHub issue](https://github.com/apptentive/apptentive-ios/issues)!

This release also adds support for displaying Asset Catalog app icons.

2014-08-19 pkamb v1.5.5
--------------------------------

This release improves the Message Center user interface. The Message Center background is now white, rather than a transparent panel. Message bubbles now appear in the tint color of your app, or the tint color you set on ATConnect. Default profile pictures have been improved, and other small improvements have been made.

This release also improves error handling when creating Events with `customData`. An Event's `customData` dictionary will only be sent if it conforms to the `isValidJSONObject:` method of `NSJSONSerialization`.

Finally, `addParseIntegrationWithDeviceToken:` has been added for integrating with Parse's Push Notification service.

2014-07-21 pkamb v1.5.4
--------------------------------

This release changes the App Store rating URL to open the "Reviews" tab directly in iOS 7.1+. #110

We have also fixed an issue where the text selection loupe showed through Message Panel to the view beneath. #114

French Canadian localization strings have been added to the SDK. iOS 8 is required to differentiate between French and French Canadian.

Finally, we have added new API methods for attaching `customData` and `extendedData` to events:  

  - `engage:withCustomData:fromViewController:`
  - `engage:withCustomData:withExtendedData:fromViewController:`

We have also added methods to easily construct these `extendedData` dictionaries in the specific Apptentive format:  

  - `extendedDataDate:`
  - `extendedDataLocationForLatitude:longitude:`
  - `extendedDataCommerceWithTransactionID:affiliation:revenue:shipping:tax:currency:commerceItems:`
  - `extendedDataCommerceItemWithItemID:name:category:price:quantity:currency:`

2014-06-30 pkamb v1.5.3
--------------------------------

This release fixes an issue where the Rating Prompt's "Require Email" option was not being utilized.

Support has also been added for remote configuration of Apptentive branding. Depending on your Apptentive plan, branding can now be toggled remotely.

Branding was formerly controlled by the `showTagLine` property, which has now been removed. The `initiallyHideBranding` property has been provided to control the app's initial experience before Apptentive's server-based configuration can be fetched.

2014-06-12 pkamb v1.5.2
--------------------------------

This release fixes a crash when submitting a piece of Feedback without an email address after tapping "No" on the Enjoyment Dialog. This bug affected versions 1.4.3, 1.5.0, and 1.5.1. If you are using one of these releases, we strongly recommend you upgrade your Apptentive SDK as soon as possible.

Additionally, the current iOS version is now logged as, for example, "7.1.1" whereas it was formerly "Version 7.1.1 (Build 11D201)".

2014-06-10 wooster, pkamb v1.5.1
--------------------------------

This release fixes a crash when showing Surveys in iOS 5 or iOS 6 from Apptentive v1.5.0. Surveys have additionally been disabled remotely for devices using Apptentive 1.5.0 and running an OS version prior to iOS 7. We recommend upgrading immediately from 1.5.0 if you are using Surveys and support legacy devices.

This release also includes fixes for the new [CocoaPods Trunk](http://blog.cocoapods.org/CocoaPods-Trunk/) service and release process.

The `showTagLine` property of `ATConnect` now makes the "Powered By Apptentive" logo in Message Center unclickable in addition to hidden.

Finally, we have changed the language code used for delivering localizations to use `[[NSLocale preferredLanguages] firstObject]` rather than use the `NSLocaleLanguageCode` locale component.


2014-05-27 wooster, pkamb v1.5.0
--------------------------------

This release moves Surveys to the engagement framework. You will now be able to target surveys to events that you `engage:` in your app. This change enables surveys to be chained with other interactions, such as the Ratings Prompt. From your Apptentive dashboard, you can now present a Survey if someone answers "No" to your "Do you Love App_Name?" prompt.

This release also fully removes the `ATAppRatingFlow.h` and `ATSurveys.h` header files. You can now simply import `ATConnect.h` when using Apptentive.

If you were using a version prior to 1.5.0, please read [MigratingTo_1.5.0.md](docs/MigratingTo_1.5.0.md) for information on how to migrate your API calls to this release. We are sorry for the inconvenience, but we hope the new features will more than make up for it!

Finally, we have migrated and improved our documentation for this release. The GitHub README now presents a smaller and simpler overview of Apptentive, and links to relevant sections on the [Apptentive Documentation](http://www.apptentive.com/docs/) site.


2014-05-05 wooster, pkamb v1.4.3
--------------------------------

This release adds checks to ensure that custom person data is sent in a timely manner and is immediately visible in the dashboard alongside messages.

Added `debuggingOptions` property on ATConnect that allows the developer to specify debug logging preferences for their app. Use `debuggingOptions` to hide the debug panel or limit the debug logging of HTTP requests.

Also fixes an issue where Chinese and Japanese keyboard input could hide buttons in the Feedback dialog.

Fixes:

* IOS-489 Chinese input hides feedback dialog buttons.
* IOS-381 Japanese input hides feedback dialog buttons.
* IOS-478 Issue where setting custom person data is not synced to server.
* IOS-370 Investigate sending order of Person and Message.
* IOS-485 HTML Response logs contents of the HTML.
* `Contains` operator should be case insensitive.

2014-04-18 wooster, pkamb v1.4.2
--------------------------------

This release adds push notification integration with Amazon Web Services (AWS) Simple Notification Service (SNS).

Use `addAmazonSNSIntegrationWithDeviceToken:` to enable SNS push notifications.

Fixes:

* IOS-461 Add integration with Amazon SNS
* #90 ATLogger fails to catch exception if no space left on device
* #91 ATAppConfigurationUpdateTask needs to retain self before updating task state

2014-04-13 wooster, pkamb v1.4.1
--------------------------------

Bug fix release for interaction codepoint encoding.

Code points are returned from the server with their components URL encoded. This fix makes the client properly recognize them.

Fixes:

* IOS-479 URL encode each token of a codepoint

2014-04-07 wooster, pkamb v1.4.0
--------------------------------

This marks the first release of a more generalized engagement framework. This will allow us to chain interactions together in interesting ways, provide better server-side configuration of what customers see and when they see it, and lay the foundation for some very interesting features in the future.

If you were using a version prior to 1.4.0, please read [MigratingTo_1.5.0.md](docs/MigratingTo_1.5.0.md) for information on how to migrate your API calls to this release. We are sorry for the inconvenience, but we hope the new features will more than make up for it!

Fixes:

* Lots of changes for the engagement framework.
* IOS-447 Add `identifierForVendor` as device property.
* [Fix](https://github.com/apptentive/apptentive-ios/commit/58e098850d75bb35fb5572cfd9d63b79aa45949f) for a memory leak in `ATInteractionUsageData`.

2014-03-29 wooster, pkamb v1.3.0
--------------------------------

Important:

* We've (provisionally) dropped iOS 4.x support. If you really need iOS 4.x support, please contact us.
* We added `AssetsLibrary` to the list of required frameworks in this version (part of the fix for IOS-409).

Fixes:

* IOS-426 Drop iOS 4 Support
* IOS-414 Add convenience method for integrating with Urban Airship (`addUrbanAirshipIntegrationWithDeviceToken:`)
* IOS-408 Dragging down in message center moves the keyboard as well
* IOS-388 Change `build_distribution.py` to build Release rather than Debug builds
* IOS-429 Remove unused images in SDK
* IOS-420 Text clipped in screenshot instructions
* IOS-398 Crash in TTTAttributedLabel
* IOS-421 Pull in image compression improvements
* IOS-409 Sending horizontal panorama photos crashes message center
* #84 dismissMessageCenterAnimated does not call completion block in some cases
* #83 Calling dismissMessageCenterAnimated can break future calls to presentMessageCenterFromViewController
* IOS-422 Ensure device info is sent before retrieving Interactions.
* IOS-449 Clicking next from email entry doesn't highlight message text entry.

2014-03-10 wooster, pkamb v1.2.9
--------------------------------

This release adds several small fixes to alleviate common support requests.

Fixes:

* IOS-415 Allow `initialUserEmailAddress` to be updated after sending feedback with no email
* IOS-418 Ability to delete a previously entered email
* Compressed images with ImageOptim
* IOS-394 Log warning if passed view controller is nil
* IOS-364 Don't fetch surveys until at least one DeviceInfo has been sent
* IOS-380 Re-add "sending..." label to pending messages

2014-02-20 pkamb v1.2.8
-----------------------

This release fixes several issues reported by developers. We now strip NSAssert calls from the Apptentive static library. Also fixes an issue where setting a nil email address caused problems with the email validator. Additional debug logging added to make API key issues easier to recognize and debug.

Fixes:

* IOS-387 and #79 Set `ENABLE_NS_ASSERTIONS` to `NO` in both Debug and Release builds. (NSAssert calls now ignored).
* IOS-386 Fixes crash when setting nil email for `initialEmailAddress`.
* IOS-383 Added debug messages to help developer notice when API key is invalid or not set.
* IOS-384 Added Kahuna integration key constant.
* IOS-379 Added additional information to readme about responding to 'Unread Message' notifications.
* Added Swedish localization file to FeedbackDemo.

2014-02-12 wooster, pkamb v1.2.7
--------------------------------

This release adds a `BOOL` return type to the `engage:` method, allowing the developer to take action if an interaction is or isn't shown. The `initiallyUseMessageCenter` property has been added to set the initial Message Center state; this will be overridden when the Apptentive configuration file is first downloaded.

This release also makes some behind-the-scenes tweaks to the Engagement Framework.

Fixes:

* IOS-354 Add BOOL return type to `engage:` method
* Change ATEvent monitoring from NSAssert to ATLogError.
* Made changes to Engagement Framework criteria:
* IOS-375 Add `is_update_version` to Enagagement Framework criteria
* IOS-377 Change `days_since...` to `time_since...` in Engagement Framework criteria.
* IOS-373 Add `build` property to Interactions.
* IOS-378 Add API method to set initial/local `useMessageCenter` setting

2014-01-27 wooster, pkamb v1.2.6
--------------------------------
This release adds support for message attachments. These text, image, or file attachments will be seen in your Apptentive online dashboard, but will not be visible in Message Center on the device.

Fixes:

* IOS-368 Added cases for always or never showing an interaction based on its criteria.
* IOS-363 Changed key to "hardware" from "model". Human readable string "model" will now be set on server.
* IOS-172 Prevent duplicate Message Center automated messages
* [Issue #70](https://github.com/apptentive/apptentive-ios/issues/70) unreadCount incremented when typing a message
* IOS-310 unreadMessageCount incremented when typing a message
* IOS-341 Investigate loading of initial config file at app launch.
* IOS-355 Strip whitespace from Survey text response
* IOS-356 Can't see send button in Message Center with white tintColor
* IOS-357 Add support for hidden text/file messages

2014-01-10 wooster, pkamb v1.2.5
--------------------------------
This release fixes some minor issues and bugs. It includes some compatibility fixes for CocoaPods users and fixes for some visual issues on iOS 7.

Fixes:

* [Issue #74](https://github.com/apptentive/apptentive-ios/issues/74) Compilation errors when adding TTTAttributedLabel as a cocoapod
* [Issue #75](https://github.com/apptentive/apptentive-ios/issues/75) Xcode build warnings
* IOS-196 Add ARM 64 architecture support
* IOS-229 Log debug info about why Survey was not shown.
* IOS-242 FeedbackDemo: Survey text and tag
* IOS-331 Profile page has both back and done buttons.
* IOS-338 Text behind "No Email Address?" alert becomes pixelated.
* IOS-343 Add `application_build` to engagement framework.
* IOS-345 Message Center arrow visual issue
* IOS-347 Switch to using XCTest from SenTest

2013-12-20 wooster, pkamb v1.2.4
--------------------------------
This release includes a UI refresh for iOS 7. Specifically, the message center and message panel both have completely new UIs.

Our previous UI should still work for iOS 4.3-6, with the new UI showing up on iOS 7+. There were a significant number of changes made, so we suggest you take a look and test things out with your app to see if we missed anything or if things don't look nice inside your app.

Fixes:

* [Issue #65](https://github.com/apptentive/apptentive-ios/issues/65) Long response is truncated in message centre on the device
* Fixes a crash caused by setting link attributes after text on TTTAttributedLabels.
* IOS-165 Skeuomorphic "note pad" background of Message Center in iOS 7?
* IOS-201 Gravatar icon doesn't show up properly
* IOS-230 Message hyperlinks are not clickable on iOS
* IOS-259 Add `time_ago` Interaction criteria
* IOS-276 Send milliseconds in Apptentive metrics
* IOS-281 Blur screen behind Message Center UI
* IOS-287 Message custom data should only be sent with the first message in a Message Center session
* IOS-288 Don't send custom data with automated messages
* IOS-293 Send customData with ATFileMessages
* IOS-303 Urban Airship push notifications.
* IOS-332 Message Center avatars are fetched from server on every load
* IOS-336 Crash when selecting a photo
* IOS-337 Crash and/or hang taking photos on iPad
* IOS-340 Notification or return value when rating flow was not shown.

2013-11-22 wooster, pkamb v1.2.3
--------------------------------
This is a release solely to fix a crash related to database migration in iOS 7.

iOS 7 switched the SQLite backing store for Core Data to use write ahead logging (WAL), which make the datastore no longer consist of a single file, but several. When performing database migrations, we were creating an upgraded database then moving it into the location of the old database. Unfortunately, the `-wal` and `-shm` sidecar files that now accompanied that old database were there alongside the new upgraded database. Since these were no longer valid when SQLite tried to load them along with the new database, there were some weird exceptions and crashes happening.

This release attempts to fix those problems. All new databases are created with the previous iOS default, DELETE mode. When we migrate databases with WAL mode set, we now delete the `-wal` and `-shm` sidecars before moving the new database into place. We also attempt to detect corrupt databases in existing installations and remove them if they exist. Finally, we've added a canary to tell us if we crashed while setting up our database. If we did, we delete the database and start it over from scratch.

Fixes:

* [Issue #71](https://github.com/apptentive/apptentive-ios/issues/71) SQLite error in Apptentive DB

2013-10-22 wooster, pkamb v1.2.2
--------------------------------

This release focuses on adding upgrade messages support. See the readme for information on how to use this feature.

We also added custom data on individual messages. See the docs/APIChanges.md for details.

Note that you'll need to add Accelerate.framework to your project now, if it's not already there.

Fixes:

* IOS-202 UIActionSheet not dismissing in photo selector is causing crash
* Fixes [Issue #62](https://github.com/apptentive/apptentive-ios/issues/62) Make font fits width on message composer screen
* IOS-222 Generalized engagement framework for interactions
* IOS-223 UpgradeMessage UI: Display a message when users upgrade their app to the latest version
* IOS-230 Message hyperlinks are not clickable on iOS
* IOS-237 Support for custom data on messages
* IOS-240 FeedbackDemo: Change text for after they click 'Rate'
* IOS-241 FeedbackDemo: Remove the beta symbol
* IOS-249 Ensure background message fetch doesn't resurrect task queue
* IOS-252 Crash when canceling photo selection on iPad + iOS 7
* IOS-254 "We're Sorry!" message cut off on iPad
* IOS-257 Message Center read event not including message ID
* IOS-258 3rd-Party notification services configuration

2013-10-09 wooster, pkamb v1.2.1
-------------------------
Fixes:

* IOS-233 "Write a Review" is grayed out when using StoreKit
* #59 'Write a Review' button disabled when app store is shown
* IOS-187 Entering text in one free form field overrides another free form field's data
* IOS-234 Add `distribution_version` to API

This release fixes an issue where iOS 7 disabled the "Write a Review" button on an app page when viewed within StoreKit. For this release, we will be switching back to the URL method of opening the page in the App Store app.

We strongly recommend updating to this version.

2013-10-08 wooster v1.2.0
-------------------------
Fixes:

* IOS-199 Contact info Name field should have word capitalization set
* IOS-200 Suggestion for "singleline" survey question type
* IOS-226 Translations of new strings
* More aggressive about updating person information.

This release also adds a mechanism to require email addresses via server setting.

2013-09-24 wooster v1.1.1
-------------------------
This is a compatibility release for iOS 7.

Fixes:

* IOS-160 Red glow under FeedbackDemo keyboard
* IOS-162 White "Message Center" title bar text can't be seen on iOS 7 white title bars.
* IOS-166 Status bar overlap issues in Message Center "Send a Photo" view
* IOS-167 Tapping Survey text entry cell results in haphazard scrolling
* IOS-171 Text entry for messages should be redone for iOS 7
* IOS-181 App hangs in iOS 7 after "No email Address?" input field alert.
* IOS-183 Unable to attach screenshot on iPad
* IOS-184 After selecting image and pressing done no action sheet is presented
* IOS-190 Survey Description Obscured when Adding Free form Text
* IOS-193 Contact info panel in MC is scrolled down too far
* IOS-194 Message Center doesn't handle rapid keyboard appearing/disappearing
* IOS-195 Handle case where message center is disabled and no valid email address

Other changes:

* Deprecated `useMessageCenter` property in favor of server-based configuration.
* Added debug messages to the rating flow for debugging ratings flow problems.
* Renamed English.lproj to en.lproj to fix Application Loader warning on app submission.
* Made `showTagline` setting work for Apptentive logo on person details screen.

2013-08-29 wooster v1.1.0
-------------------------
This release focuses on support for Enterprise Surveys.

These are mostly changes on the web side of things, but there are also some client changes:

* Moved survey responses into Core Data.
* IOS-119 Implement short v. long survey text response type
* IOS-116 Implement new survey submission endpoint

Other changes for IOS 7 forward compatibility:

* IOS-181 App hangs in iOS 7 after "No email Address?" input field alert.

Other fixes:

* apptentive-ios#45 Renames `ATMessage` to `ATAbstractMessage` because of naming conflict with `AirTraffic.framework`
* We accidentally used the Traditional Chinese localization for both Traditional and Simplified Chinese. This has been fixed.
* Added `useMessageCenter` property on `ATConnect` for those who don't want to use Message Center.

2013-08-18 wooster v1.0.1
-------------------------
Deprecating the `-addCustomData:withKey:` and `-removeCustomDataWithKey:` methods in `ATConnect`.

In their place, use these new methods, which add custom data about devices and people:

```
/*! Adds an additional data field to any feedback sent. object should be an NSDate, NSNumber, or NSString. */
- (void)addCustomPersonData:(NSObject<NSCoding> *)object withKey:(NSString *)key;
- (void)addCustomDeviceData:(NSObject<NSCoding> *)object withKey:(NSString *)key;

/*! Removes an additional data field from the feedback sent. */
- (void)removeCustomPersonDataWithKey:(NSString *)key;
- (void)removeCustomDeviceDataWithKey:(NSString *)key;
```

Also deprecating the `appName` property on `ATAppRatingFlow`. Now, the display name of the application used in our framework can be set server-side.

Per IOS-144 and IOS-145, we now have much better localizations across many more languages.

We have started on iOS 7 compatibility with IOS-157, IOS-159, IOS-164, IOS-168, and IOS-169. We covered some of the major parts, but there's more to come!

Fixes:

* IOS-144 Get incremental updates of localizable strings for Message Center
* IOS-145 Get missing strings from surveys localized
* IOS-149 Don't allow nested key/value pairs for custom data.
* IOS-157 Unread message count not centered in FeedbackDemo
* IOS-159 Spacing between top of email form and the status bar
* IOS-156 Message Center on Original iPad locks to portrait mode
* IOS-164 Message Center background color: white vs. grey
* IOS-168 Attaching photo causes crash on iOS 7
* IOS-169 UITextView metrics changed in iOS 7
* IOS-173 Make client play nicely with location updates and file protection
    * This was a crasher caused when background apps were started before the phone was unlocked.
* IOS-174 Initial email address and name not hooked up to person object
* IOS-175 Add warning if resource bundle isn't found in app
    * If the app isn't properly integrated, and you run it in the Simulator, this will warn you with an alert.
* IOS-176 Select/Copy/Paste menu is broken
* IOS-179 Localization overflow in Message Center feedback form title
* apptentive-ios#44 Doesn't work well in portrait mode on iPad
* apptentive-ios#26 More localizations

2013-06-28 wooster v1.0.0
-------------------------
There are a lot of major API changes. They are documented in docs/APIChanges.md

* Fixes IOS-127 Make some APIs private for Message Center release
* Fixes IOS-129 Simplify SDK API
* Fixes IOS-130 Rename add info API call
* Fixes IOS-128 Remove feedback API for Message Center
* Fixes IOS-103 Make ratings flow easier
* Fixes IOS-136 Create personal info editing screen
* Many, many other changes.

Note that for apps created before June 28, 2013, please contact us to have your account
upgraded to the new Message Center UI on our website. If you have any questions at all,
please let us know!

2013-06-07 wooster v0.4.9
-------------------------
We've finally added support for surveys with tags.

- To check for surveys, call `ATSurveys +(void)checkForAvailableSurveys` as usual.
- Listen for the `ATSurveyNewSurveyAvailableNotification`.
- Check to see if surveys with a given set of tags are available with `ATSurveys +(BOOL)hasSurveyAvailableWithTags:(NSSet *)tags`.
- Display a survey with tags with: `ATSurveys +(void)presentSurveyControllerWithTags:(NSSet *)tags fromViewController:(UIViewController *)viewController`.

Other fixes:

* Fixes IOS-105 Add Russian Localization
    * Thanks to Захаров Дмитрий for the translation!
* Fixes IOS-120 Get localizations for iOS Client strings
* Fixes IOS-63 Implement new client API for surveys (survey tags)
* Fixes IOS-106 Limit connections to 2 at once
    * This prevents a potential problem in situations where the number of connections is limited. See [the problem AFNetworking+TestFlight hit](https://github.com/AFNetworking/AFNetworking/issues/307).
* Fixes IOS-92 Demo app should show a message when the API key is not set
    * This will hopefully be a nice reminder, rather than an irritation.
* Fixes IOS-85 Setting days before re-prompt to 0 doesn't work as expected
    * If this value is 0, we will now only prompt once per update.
* Fixes IOS-84 Re-prompt only once per version
    * We will only prompt twice per update total (prompt and re-prompt).
* Fixes IOS-62 Add support for repeat surveys
* Fixes IOS-99 Add Callback after a user agrees to rate the app
    * You can now listen for `ATAppRatingFlowUserAgreedToRateAppNotification` to know when a user agrees to rate the app.
* apptentive/apptentive-ios#32 Showing the rating dialog from a modal
* IOS-108 Fix for launches not being detected after IOS-76 changes
* IOS-107 Fix warnings in PrefixedJSONKit
* Fixes IOS-124 Surveys with tags shouldn't show up in bare surveys calls
* Fixes IOS-126 Long survey answers are truncated
* Also brings in pull requests #38 and #39.

2013-05-31 wooster v0.4.8a
--------------------------
This is a localization minor bump. There are still a few edge cases in the UI.

Thanks to Robert Lo Bue and Applingua (with help from SpaceInch) for the new localizations!

2013-02-01 wooster v0.4.8
-------------------------
This is a bug fix release.

* Fixes IOS-80 Use StoreKit to show product page when reviewing app
    * Your users on iOS 6 and above will no longer be bounced out of the app to rate your app.
    * To use this, you'll need to link against StoreKit and build with the iOS 6 SDK.
* Fixes IOS-86 Always dismiss keyboard on feedback dialog going away
* Fixes IOS-76 Update launch logic for iOS 4 API (better last use of app metrics for iOS 4+)
* Fixes IOS-83 Distribution build script phase is buggy and runs even when not necessary
* Fixes IOS-72 Find out more button doesn't work in iOS 6
* Fixes IOS-28 Show success message on survey completion when configured
* Fixes IOS-15 Privacy information on info screen
* Fixes [Issue #30](https://github.com/apptentive/apptentive-ios/issues/30) JSONKit warnings in Xcode 4.6
* Fixes IOS-96 Text cut off in screenshot view in landscape
* Fixes IOS-94 Right side of feedback UI doesn't work on iPhone app running on iPad (in landscape)
* Fixes IOS-97 Sending file attachments is writing files to disk a lot
* Fixes IOS-88 Send CP suffix on client version for cocoa pod versions

2012-09-27 wooster v0.4.7
-------------------------
Major change:
* We're dropping armv6 support. This means no more iPhone 3G or iPod Touch 2 support. This is in line with what we're seeing from app developers and other vendors of 3rd party libraries. If you *really* need armv6 support, let us know.

Other changes:

* Fixes IOS-71 Add callback after survey completion
  See the `ATSurveys.h` header for details.
* Added `showTagline` property on `ATConnect`. This allows you to hide the "Powered by Apptentive" logo text.
* Fixes IOS-78 Always send dates in english

  This bug was causing some dates to be sent localized to the server. Oops.
* Fixes IOS-79 Allow dev to prompt user to re-rate after new version installed

  When the "Reset rating prompt counters when app version changes" settings is enabled, if a user has already rated the app, that will be reset when they upgrade the app. The upshot of this is, users will be prompted to rate the app again after upgrade. You may want to do this if you want users to re-rate the app on a version change, as the iOS App Store is heavily geared towards ratings and reviews for the current version. This change makes our behavior match what developers expect when checking that box on the Apptentive site.
* URL Loading changes:
  * Better cache policy handling, per http://blackpixel.com/blog/1659/caching-and-nsurlconnection/
  * Better URL redirection handling.
* Fixes IOS-39 No option to cancel a photo/screenshot attachment?
  * To cancel a screenshot or photo attachment, just drag it away from the paperclip.


2012-09-11 wooster v0.4.6
-------------------------
One major change in the API:
* The `shouldTakeScreenshot` property of `ATConnect` is now `NO` by default.

Some changes for iOS 6 compatibility:
* Fixes for `viewDidUnload` deprecation (IOS-66 Fixes for deprecated API in iOS 6)
* Retrieves review URL for app store from our server (IOS-64)
* Fixes issue when taking a photo with the iPad camera.

So, due to iOS 6 changing the review URL for opening the App Store and submitting a review, we're now computing this on the server.

Other fixes:
* IOS-60 Respect "cache-expiration" setting returned with configuration
* #23 Modal window closes after feedback (Also logged as IOS-68 Modal Dialog Issue)
* IOS-70 Getting surveys returns 404 on no surveys
* IOS-67 Populate the feedback source field with "enjoyment_dialog" when launched from the ratings prompt
* Changes to `shouldTakeScreenshot` property with existing images attached to feedback work more like one would expect.

Of these, the configuration expiration lets us be less aggressive in retrieving new configurations from the server on startup. #23 fixes a problem in which presenting the feedback dialog from within a modal view controller caused view hierarchy issues with the modal view controller. IOS-70 was, in cases where the app had no surveys, sometimes preventing configuration settings being retrieved from the server. IOS-67 lets us track which pieces of feedback were generated by people saying they don't like the app in the ratings flow.

2012-08-29 wooster v0.4.6
-------------------------
Changes for OS X compatibility:
* Added backing ivars for properties.
* Removed methods for displaying different feedback window types on OS X.

2012-08-29 wooster v0.4.5
-------------------------
Fixes in this version:

* Fixes IOS-65, `[[UIApplication sharedApplication] keyWindow]` being nil after feedback window is dismissed.
* Fixes leak of feedback and custom placeholder text by feedback controller.
* Current feedback is cleared before feedback window is shown by ratings and after that window is dismissed.

2012-08-08 wooster v0.4.4
-------------------------
Major changes:

We switched from JSONKit to our PrefixedJSONKit library, which prefixes all the JSONKit symbols. In this case, our prefix is `AT`. So, we no longer conflict with JSONKit. If you were using JSONKit already and removed it in favor of ours, you'll want to add the original JSONKit back to your project rather than using the PrefixedJSONKit project.

Minor changes:
- Fix for IOS-59, which tweaks how `ATBackend` stops and restarts the task queue.

2012-07-24 wooster v0.4.3
-------------------------
* Fix for IOS-41, wherein the metrics were being sent incorrectly and metric for
  text responses was being sent after the metric for survey submission.

2012-07-23 wooster v0.4.2
-------------------------
* Fix for [#20](https://github.com/apptentive/apptentive-ios/issues/20), wherein the image picker on iPad would cause the app to crash.

2012-07-22 wooster v0.4.2
-------------------------

* IOS-52: Requests sent before API key is set won't succeed until next app start

	Thanks to [@kgn](https://github.com/kgn) for finding this and [proposing a fix](https://github.com/apptentive/apptentive-ios/pull/19). The fix we've chosen is a
	bit more involved. We are now making each of our various URL requests be handled
	by `ATTask` objects, which can tell the task queue whether or not they're able
	to be executed at the current time. For the case of API requests, that will be
	`NO` until such time as the API key is set.

2012-07-09 wooster v0.4.2
-------------------------
Minor changes:
* Adding Spanish localization courtesy of [Babble-on Inc](http://www.ibabbleon.com/).
* Fixes from [@kgn](https://github.com/kgn) for crash on original iPad and disabled styling on Send button ([pull request 18](https://github.com/apptentive/apptentive-ios/pull/18)).
* IOS-48: Use count is incremented twice at startup, again at location prompt See [a8dedf6abb5b08342aa564ca2a26fcbae80c9d6f](https://github.com/apptentive/apptentive-ios/commit/a8dedf6abb5b08342aa564ca2a26fcbae80c9d6f)


2012-06-25 wooster v0.4.1
-------------------------
Major changes:

The surveys module has been integrated into `ApptentiveConnect` proper, as the survey features are now live for all users on the site. If you have previously added the Surveys module to your app, you will need to update the configuration by removing it from your app and including the `ATSurveys.h` header file.

Minor changes:
* Consistent use of tabs for indents.
* New icons with new Apptentive logo.

2012-06-01 wooster v0.4.0
-------------------------
Major changes:

The metrics module has been integrated into `ApptentiveConnect` proper. Now that you can enable and disable metrics from the website, it didn't make sense to keep them separate.

Bug fixes:
* IOS-40: On debug builds, the configuration is updated much more often to aid debugging. See [df7aa47dce369e6caad8c18ff72b8f9cb0485050](https://github.com/apptentive/apptentive-ios/commit/df7aa47dce369e6caad8c18ff72b8f9cb0485050)
* IOS-41: Added metrics for surveys and for feedback submission. See [e4ce211834737c08b8a5fe9591dffc14b884304f](https://github.com/apptentive/apptentive-ios/commit/e4ce211834737c08b8a5fe9591dffc14b884304f)
* IOS-38: Fixed bug where the paperclip blocked feedback text when there was no email field and no thumbnail. See [f0d7c6e52ee8053653d5ae346ddebb626f9b048e](https://github.com/apptentive/apptentive-ios/commit/f0d7c6e52ee8053653d5ae346ddebb626f9b048e)
* IOS-31: Now sending time to completion of surveys with the response. See [40b1e1e221a0fe60826da2b5ff31877485c72451](https://github.com/apptentive/apptentive-ios/commit/40b1e1e221a0fe60826da2b5ff31877485c72451)
* IOS-42: Should use the localized app name in the ratings flow, if available. See [dc2f59ef5cd347ecc5aa332323d9894092f635e7](https://github.com/apptentive/apptentive-ios/commit/dc2f59ef5cd347ecc5aa332323d9894092f635e7)
* IOS-43: Fixes a bug where sometimes the ratings dialog was not shown at startup due to network reachability. See [717b010ee01bbfd87ee3cca957e7c5bf76d0f648](https://github.com/apptentive/apptentive-ios/commit/717b010ee01bbfd87ee3cca957e7c5bf76d0f648) for more info.
* IOS-36: Fixes bug where the alert view asking for email addresses looks funny in landscape mode. This fix only works on iOS 5+. See [b1aa55dac9b4dc6ae9b10440901129572d271b21](https://github.com/apptentive/apptentive-ios/commit/b1aa55dac9b4dc6ae9b10440901129572d271b21)
* IOS-44: Where screenshots appear too small on Retina display devices. See [7a0d877b523a7f58ba94789bda6ceeebaaff1bd0](https://github.com/apptentive/apptentive-ios/commit/7a0d877b523a7f58ba94789bda6ceeebaaff1bd0)
* IOS-45: In which the application frame wasn't properly taken into account and whitespace appeared in the screenshot under non-default orientations. See [e8a7358f329797812e9d944412bd6708b0d238d4](https://github.com/apptentive/apptentive-ios/commit/e8a7358f329797812e9d944412bd6708b0d238d4)

2012-03-26 wooster v0.3.3
-------------------------

Fixes problem wherein app wouldn't use the correct ratings configuration from the server.

2012-03-25 wooster
------------------
Major changes:

* Start of version 0.3.
* Ratings flow configuration is now done server-side. Old parameters in SDK no longer exist.
* There are now server-side on/off switches for both ratings and metrics.
* Added initial version of surveys.
* Ratings parameter counters (days of use, significant events) can be reset on version upgrade.
* Including armv6 (non-thumb) architecture in all libraries.
* "Distribution" target in FeedbackDemo builds a static library distribution.
* Application exit events wired up in Metrics module.
* Adding `initialName` property to ATConnect for pre-populating the user's name.

##### Metrics
The metrics module can be used by simply linking against the `libApptentiveMetrics.a` static library. That's it. You can turn metrics on or off server side in your app settings.

##### Surveys
This is a very rough initial version of surveys. To use, link against `libApptentiveSurveys.a`.

Specific bug fixes and features:

* IOS-3: App Exit events don't seem to be sent?
* IOS-6: $ARCHS_STANDARD_32_BIT is now armv7 only, needs to be changed to armv6 and armv7
* IOS-11: Surveys Module on iOS
* IOS-21: Support for Server Side Ratings Settings
* IOS-22: Option to clear ratings parameter values (days of use, events, etc.) on version upgrade
* IOS-34: Add support for prepopulating the user's name

2012-01-13 wooster
------------------
* Start of version 0.2.
* Added support for adding and removing extra data to feedback.
* Added initial version of metrics module.
* Added support for optionally showing or hiding the email address field on feedback.
* Added support for setting an initial email address on the feedback form.

To add data to feedback, use these methods on `ATConnect`:

``` objective-c
- (void)addAdditionalInfoToFeedback:(NSObject<NSCoding> *)object withKey:(NSString *)key;
- (void)removeAdditionalInfoFromFeedbackWithKey:(NSString *)key;
```

The data objects should, at this time, either be of type `NSString` or `NSDate`. They will be added to the `record[data]` hash, with the key as the key, as in `record[data][key]`.

If you add the metrics module to your project, it will load on run. It's experimental at this point, so I wouldn't recommend using it quite yet.

You can use these properties to control email field behavior on the feedback form:

``` objective-c
@property (nonatomic, assign) BOOL showEmailField;
@property (nonatomic, retain) NSString *initialEmailAddress;
```

`showEmailField` controls whether or not the email address field is shown on the feedback form. `initialEmailAddress` can be used to set the initial email address that populates the field. Note: if the user submits feedback with a different email address, `initialEmailAddress` will not be used.
