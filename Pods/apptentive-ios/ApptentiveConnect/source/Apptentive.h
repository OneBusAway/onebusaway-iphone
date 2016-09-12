//
//  Apptentive.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/12/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//


#import <UIKit/UIKit.h>

#define kApptentiveVersionString @"3.2.1"
#define kApptentivePlatformString @"iOS"

NS_ASSUME_NONNULL_BEGIN

@protocol ApptentiveDelegate
, ApptentiveStyle;

/** Notification sent when Message Center unread messages count changes. */
extern NSString *const ApptentiveMessageCenterUnreadCountChangedNotification;

/** Notification sent when the user has agreed to rate the application. */
extern NSString *const ApptentiveAppRatingFlowUserAgreedToRateAppNotification;

/** Notification sent when a survey is shown. */
extern NSString *const ApptentiveSurveyShownNotification;

/** Notification sent when a survey is submitted by the user. */
extern NSString *const ApptentiveSurveySentNotification;

/**
 When a survey is shown or sent, notification's userInfo dictionary will contain the ApptentiveSurveyIDKey key.
 Value is the ID of the survey that was shown or sent.
 */
extern NSString *const ApptentiveSurveyIDKey;

/** Supported Push Providers for use in `setPushNotificationIntegration:withDeviceToken:` */
typedef NS_ENUM(NSInteger, ApptentivePushProvider) {
	/** Specifies the Apptentive push provider. */
	ApptentivePushProviderApptentive,
	/** Specifies the Urban Airship push provider. */
	ApptentivePushProviderUrbanAirship,
	/** Specifies the Amazon Simple Notification Service push provider. */
	ApptentivePushProviderAmazonSNS,
	/** Specifies the Parse push provider. */
	ApptentivePushProviderParse,
};

/**
 `Apptentive` is a singleton which is used as the main point of entry for the Apptentive service.

 ## Configuration

Before calling any other methods on the shared `Apptentive` instance, set the API key:

     [[Apptentive sharedConnection].APIKey = @"your API key here";

## Engagement Events

 The Ratings Prompt and other Apptentive interactions are targeted to certain Apptentive events. For example,
 you could decide to show the Ratings Prompt after an event named "user_completed_level" has been engaged.
 You can later reconfigure the Ratings Prompt interaction to instead show after engaging "user_logged_in".

 You would add calls at these points to optionally engage with the user:

     [[Apptentive sharedConnection] engage:@"completed_level" fromViewController:viewController];

 See the readme for more information.

## Notifications

 `ApptentiveMessageCenterUnreadCountChangedNotification`

 Sent when the number of unread messages changes.
 The notification object is undefined. The `userInfo` dictionary contains a `count` key, the value of which
 is the number of unread messages.

 `ApptentiveAppRatingFlowUserAgreedToRateAppNotification`

 Sent when the user has agreed to rate the application.

 `ApptentiveSurveySentNotification`

 Sent when a survey is submitted by the user. The userInfo dictionary will have a key named `ApptentiveSurveyIDKey`,
 with a value of the id of the survey that was sent.

 */
@interface Apptentive : NSObject

///---------------------------------
/// @name Basic Usage
///---------------------------------
/** The shared singleton of `Apptentive`. */
+ (Apptentive *)sharedConnection;

/**
 The API key for Apptentive.

 This key is found on the Apptentive website under Settings, API & Development.
 */
@property (copy, nonatomic, nullable) NSString *APIKey;

/**
  APIKey property with legacy capitalization.

 @deprecated Capitalize `API` in the property/setter name.
 */
@property (copy, nonatomic, nullable) NSString *apiKey __deprecated_msg("Use 'APIKey' instead.");

/**
 The app's iTunes App ID.

 You can find this in iTunes Connect, and is the numeric "Apple ID" shown on your app details page.
 */
@property (copy, nonatomic, nullable) NSString *appID;

/** An object conforming to the `ApptentiveDelegate` protocol.
 If a `nil` value is passed for the view controller into methods such as	`-engage:fromViewController`,
 the SDK will request a view controller from the delegate from which to present an interaction. */
@property (weak, nonatomic) id<ApptentiveDelegate> delegate;

///---------------------------------
/// @name Interface Customization
///---------------------------------

/** The style sheet used for styling Apptentive UI.

@discussion See the [Apptentive Styling Guide for iOS](https://docs.apptentive.com/ios/customization/) for information on configuring this property.
 */
@property (strong, nonatomic) id<ApptentiveStyle> styleSheet;

///--------------------
/// @name Presenting UI
///--------------------

/**
 Determines if Message Center will be displayed when `presentMessageCenterFromViewController:` is called.

 If app has not yet synced with Apptentive, you will be unable to display Message Center. Use `canShowMessageCenter`
 to determine if Message Center is ready to be displayed. If Message Center is not ready you could, for example,
 hide the "Message Center" button in your interface.
 **/

- (BOOL)canShowMessageCenter;

/**
 Presents Message Center modally from the specified view controller.

 If the SDK has yet to sync with the Apptentive server, this method returns NO and displays a
 "We're attempting to connect" view in place of Message Center.

 @param viewController The view controller from which to present Message Center.

 @return `YES` if Message Center was presented, `NO` otherwise.
 */
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController;

/**
 Presents Message Center from a given view controller with custom data.

 If the SDK has yet to sync with the Apptentive server, this method returns NO and displays a
 "We're attempting to connect" view in place of Message Center.

 @param viewController The view controller from which to present Message Center.
 @param customData A dictionary of key/value pairs to be associated with any messages sent via Message Center.

 @return `YES` if Message Center was presented, `NO` otherwise.
 */
- (BOOL)presentMessageCenterFromViewController:(UIViewController *)viewController withCustomData:(nullable NSDictionary *)customData;

/**
 Returns the current number of unread messages in Message Center.

 These are the messages sent via the Apptentive website to this user.

 @return The number of unread messages.
 */
- (NSUInteger)unreadMessageCount;

/**
 Returns a "badge" than can be used as a UITableViewCell accessoryView to indicate the current number of unread messages.

 To keep this value updated, your view controller will must register for `ApptentiveMessageCenterUnreadCountChangedNotification`
 and reload the table view cell when a notification is received.

 @param apptentiveHeart A Boolean value indicating whether to include a heart logo adjacent to the number.

 @return A badge view suitable for use as a table view cell accessory view.
 */
- (UIView *)unreadMessageCountAccessoryView:(BOOL)apptentiveHeart;

/**
 Forwards a push notification from your application delegate to Apptentive Connect.

 If the push notification originated from Apptentive, Message Center will be presented from the view controller
 when the notification is tapped.

 @param userInfo The `userInfo` dictionary of the notification.
 @param viewController The view controller Message Center may be presented from.

 @return `YES` if the notification was sent by Apptentive, `NO` otherwise.
 */
- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController;

/**
 Forwards a push notification from your application delegate to Apptentive Connect.

 If the push notification originated from Apptentive, Message Center will be presented from the view controller
 when the notification is tapped.

 Apptentive will attempt to fetch Messages Center messages in the background when the notification is received.

 To enable background fetching of Message Center messages upon receiving a remote notification,
 add `remote-notification` as a `UIBackgroundModes` value in your app's Info.plist.

 The `completionHandler` block will be called when the message fetch is completed. To ensure that messages can be
 retrieved, please do not call the `completionHandler` block yourself if the notification was sent by Apptentive.

 If the notification was not sent by Apptentive, the parent app is responsible for calling the `completionHandler` block.

 @param userInfo The `userInfo` dictionary of the notification.
 @param viewController The view controller Message Center may be presented from.
 @param completionHandler The block to execute when the message fetch operation is complete.

 @return `YES` if the notification was sent by Apptentive, `NO` otherwise.
 */

- (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo fromViewController:(UIViewController *)viewController fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

/**
Returns a Boolean value indicating whether the given event will cause an Interaction to be shown.

 For example, returns YES if a survey is ready to be shown the next time you engage your survey-targeted event. You can use this method to hide a "Show Survey" button in your app if there is no survey to take.

 @param event A string representing the name of the event.

 @return `YES` if the event will show an interaction, `NO` otherwise.
 */
- (BOOL)canShowInteractionForEvent:(NSString *)event;

/**
 Shows interaction UI, if applicable, related to a given event.

 For example, if you have an upgrade message to display on app launch, you might call with event label set to
 `@"app.launch"` here, along with the view controller an upgrade message might be displayed from.

 @param event A string representing the name of the event.
 @param viewController A view controller Apptentive UI may be presented from. If `nil`, a view controller should be provided by the delegate.

 @return `YES` if an interaction was triggered by the event, `NO` otherwise.
 */
- (BOOL)engage:(NSString *)event fromViewController:(UIViewController *_Nullable)viewController;

/**
 Shows interaction UI, if applicable, related to a given event, and attaches the specified custom data to the event.

 @param event A string representing the name of the event.
 @param customData A dictionary of key/value pairs to be associated with the event. Keys and values should conform to standards of NSJSONSerialization's `isValidJSONObject:`.
 @param viewController A view controller Apptentive UI may be presented from. If `nil`, a view controller should be provided by the delegate.

 @return `YES` if an interaction was triggered by the event, `NO` otherwise.
*/
- (BOOL)engage:(NSString *)event withCustomData:(nullable NSDictionary *)customData fromViewController:(UIViewController *_Nullable)viewController;

/**
 Shows interaction UI, if applicable, related to a given event. Attaches the specified custom data to the event along with the specified extended data.

 @param event A string representing the name of the event.
 @param customData A dictionary of key/value pairs to be associated with the event. Keys and values should conform to standards of NSJSONSerialization's `isValidJSONObject:`.
 @param extendedData An array of dictionaries with specific Apptentive formatting. For example, [Apptentive extendedDataDate:[NSDate date]].
 @param viewController A view controller Apptentive UI may be presented from. If `nil`, a view controller should be provided by the delegate.

 @return `YES` if an interaction was triggered by the event, `NO` otherwise.
 */
- (BOOL)engage:(NSString *)event withCustomData:(nullable NSDictionary *)customData withExtendedData:(nullable NSArray<NSDictionary *> *)extendedData fromViewController:(UIViewController *_Nullable)viewController;

/**
 Dismisses Message Center.

 @param animated `YES` to animate the dismissal, otherwise `NO`.
 @param completion A block called at the conclusion of the message center being dismissed.

 @discussion Under normal circumstances, Message Center will be dismissed by the user tapping the Close button, so it is not necessary to call this method.
 */
- (void)dismissMessageCenterAnimated:(BOOL)animated completion:(nullable void (^)(void))completion;

///--------------------
/// @name Extended Data for Events
///--------------------

/**
 Used to specify a point in time in an event's extended data.

 @param date A date and time to be included in an event's extended data.

 @return An extended data dictionary representing a point in time, to be included in an event's extended data.
 */
+ (NSDictionary *)extendedDataDate:(NSDate *)date;

/**
 Used to specify a geographic coordinate in an event's extended data.

 @param latitude A location's latitude coordinate.
 @param longitude A location's longitude coordinate.

 @return An extended data dictionary representing a geographic coordinate, to be included in an event's extended data.
 */
+ (NSDictionary *)extendedDataLocationForLatitude:(double)latitude longitude:(double)longitude;

/**
 Used to specify a commercial transaction (incorporating multiple items) in an event's extended data.

 @param transactionID The transaction's ID.
 @param affiliation The store or affiliation from which this transaction occurred.
 @param revenue The transaction's revenue.
 @param shipping The transaction's shipping cost.
 @param tax Tax on the transaction.
 @param currency Currency for revenue/shipping/tax values.
 @param commerceItems An array of commerce items contained in the transaction. Create commerce items with [Apptentive extendedDataCommerceItemWithItemID:name:category:price:quantity:currency:].

 @return An extended data dictionary representing a commerce transaction, to be included in an event's extended data.
  */
+ (NSDictionary *)extendedDataCommerceWithTransactionID:(nullable NSString *)transactionID
											affiliation:(nullable NSString *)affiliation
												revenue:(nullable NSNumber *)revenue
											   shipping:(nullable NSNumber *)shipping
													tax:(nullable NSNumber *)tax
											   currency:(nullable NSString *)currency
										  commerceItems:(nullable NSArray<NSDictionary *> *)commerceItems;

/**
 Used to specify a commercial transaction (consisting of a single item) in an event's extended data.

 @param itemID The transaction item's ID.
 @param name The transaction item's name.
 @param category The transaction item's category.
 @param price The individual item price.
 @param quantity The number of units purchased.
 @param currency Currency for price.

 @return An extended data dictionary representing a single item in a commerce transaction, to be included in an event's extended data.
 */
+ (NSDictionary *)extendedDataCommerceItemWithItemID:(nullable NSString *)itemID
												name:(nullable NSString *)name
											category:(nullable NSString *)category
											   price:(nullable NSNumber *)price
											quantity:(nullable NSNumber *)quantity
											currency:(nullable NSString *)currency;


///-------------------------------------
/// @name Attach Text, Images, and Files
///-------------------------------------

/**
 Attaches text to the user's feedback.

 This will appear in your online Apptentive dashboard, but will *not* appear in Message Center on the device.

 @param text The text to attach to the user's feedback as a file.
 */
- (void)sendAttachmentText:(NSString *)text;

/**
 Attaches an image the user's feedback.

 This will appear in your online Apptentive dashboard, but will *not* appear in Message Center on the device.

 @param image The image to attach to the user's feedback as a file.
 */
- (void)sendAttachmentImage:(UIImage *)image;

/**
 Attaches an arbitrary file to the user's feedback.

 This will appear in your online Apptentive dashboard, but will *not* appear in Message Center on the device.

 @param fileData The contents of the file as data.
 @param mimeType The MIME type of the file data.
 */
- (void)sendAttachmentFile:(NSData *)fileData withMimeType:(NSString *)mimeType;

///---------------------------------------
/// @name Add Custom Device or Person Data
///---------------------------------------

/** The name of the app user when communicating with Apptentive. */
@property (copy, nonatomic, nullable) NSString *personName;
/** The email address of the app user in form fields and communicating with Apptentive. */
@property (copy, nonatomic, nullable) NSString *personEmailAddress;

/**
 Adds custom data associated with the current person.

 Adds an additional data field to any feedback sent. This will show up in the person data in the
 conversation on your Apptentive dashboard.

 @param object Custom data of type `NSDate`, `NSNumber`, or `NSString`.
 @param key A key to associate the data with.
 */
- (void)addCustomPersonData:(NSObject<NSCoding> *)object withKey:(NSString *)key;

/**
 Adds custom data associated with the current device.

 Adds an additional data field to any feedback sent. This will show up in the device data in the
 conversation on your Apptentive dashboard.

 @param object Custom data of type `NSDate`, `NSNumber`, or `NSString`.
 @param key A key to associate the data with.
 */
- (void)addCustomDeviceData:(NSObject<NSCoding> *)object withKey:(NSString *)key;

/**
 Removes custom data associated with the current person.

 Will remove data, if any, associated with the current person with the key `key`.

 @param key The key of the data.
 */
- (void)removeCustomPersonDataWithKey:(NSString *)key;

/**
 Removes custom data associated with the current device.

 Will remove data, if any, associated with the current device with the key `key`.

 @param key The key of the data.
 */
- (void)removeCustomDeviceDataWithKey:(NSString *)key;

/**
 Adds custom text data associated with the current device.

 Adds an additional data field to any feedback sent. This will show up in the device data in the
 conversation on your Apptentive dashboard.

 @param string Custom data of type `NSString`.
 @param key A key to associate the data with.
 */
- (void)addCustomDeviceDataString:(NSString *)string withKey:(NSString *)key;

/**
 Adds custom numeric data associated with the current device.

 Adds an additional data field to any feedback sent. This will show up in the device data in the
 conversation on your Apptentive dashboard.

 @param number Custom data of type `NSNumber`.
 @param key A key to associate the data with.
 */
- (void)addCustomDeviceDataNumber:(NSNumber *)number withKey:(NSString *)key;

/**
 Adds custom Boolean data associated with the current device.

 Adds an additional data field to any feedback sent. This will show up in the device data in the
 conversation on your Apptentive dashboard.

 @param boolValue Custom data of type `BOOL`.
 @param key A key to associate the data with.
 */
- (void)addCustomDeviceDataBool:(BOOL)boolValue withKey:(NSString *)key;

/**
 Adds custom text data associated with the current person.

 Adds an additional data field to any feedback sent. This will show up in the person data in the
 conversation on your Apptentive dashboard.

 @param string Custom data of type `NSString`.
 @param key A key to associate the data with.
 */
- (void)addCustomPersonDataString:(NSString *)string withKey:(NSString *)key;

/**
 Adds custom numeric data associated with the current person.

 Adds an additional data field to any feedback sent. This will show up in the person data in the
 conversation on your Apptentive dashboard.

 @param number Custom data of type `NSNumber`.
 @param key A key to associate the data with.
 */
- (void)addCustomPersonDataNumber:(NSNumber *)number withKey:(NSString *)key;

/**
 Adds custom Boolean data associated with the current person.

 Adds an additional data field to any feedback sent. This will show up in the person data in the
 conversation on your Apptentive dashboard.

 @param boolValue Custom data of type `BOOL`.
 @param key A key to associate the data with.
 */
- (void)addCustomPersonDataBool:(BOOL)boolValue withKey:(NSString *)key;

///---------------------------------------
/// @name Open App Store
///---------------------------------------

/**
 Open your app's page on the App Store or Mac App Store.

 This method can be used to power, for example, a "Rate this app" button in your settings screen.
 `openAppStore` opens the app store directly, without the normal Apptentive Ratings Prompt.
 */
- (void)openAppStore;

///------------------------------------
/// @name Add Push Notifications
///------------------------------------

/**
 Register for Push Notifications with the given service provider.

 Uses the `deviceToken` from `application:didRegisterForRemoteNotificationsWithDeviceToken:`

 Only one Push Notification Integration can be added at a time. Setting a Push Notification
 Integration removes all previously set Push Notification Integrations.

 To enable background fetching of Message Center messages upon receiving a remote notification,
 add `remote-notification` as a `UIBackgroundModes` value in your app's Info.plist.

 @param pushProvider The Push Notification provider with which to register.
 @param deviceToken The device token used to send Remote Notifications.
 **/

- (void)setPushNotificationIntegration:(ApptentivePushProvider)pushProvider withDeviceToken:(NSData *)deviceToken;

@end

/**
 The `ApptentiveDelegate` protocol allows your app to override the default behavior when an
 interaction is presented without a view controller having been specified. In most cases the
 default behavior (which walks the view controller stack from the main window's root view
 controller) will work, but if your app features custom container view controllers, it may
 behave unexpectedly. In that case an object in your app should implement the
 `ApptentiveDelegate` protocol's `-viewControllerForInteractionsWithConnection:` method
 and return the view controller from which to present the Message Center interaction.
 */
@protocol ApptentiveDelegate <NSObject>
@optional

/**
 Returns a view controller from which to present the an interaction.

 @param connection The `Apptentive` object that is requesting a view controller to present from.

 @return The view controller your app would like the interaction to be presented from.
 */
- (UIViewController *)viewControllerForInteractionsWithConnection:(Apptentive *)connection;

@end

/**
 The `ApptentiveNavigationController class is an empty subclass of UINavigationController that
 can be used to target UIAppearance settings specifically to Apptentive UI.

 For instance, to override the default `barTintColor` (white) for navigation controllers
 in the Apptentive UI, you would call:

	[[UINavigationBar appearanceWhenContainedIn:[ApptentiveNavigationController class], nil].barTintColor = [UIColor magentaColor];

 */
@interface ApptentiveNavigationController : UINavigationController
@end

@compatibility_alias ATConnect Apptentive;
@compatibility_alias ATNavigationController ApptentiveNavigationController;

/**
 The ApptentiveStyle protocol allows extensive customization of the fonts and colors used by the Apptentive SDK's UI.

 A class implementing this protocol must handle resizing text according to the applications content size to support dynamic type.
 */
@protocol ApptentiveStyle <NSObject>

/**
 @param textStyle the text style whose font should be returned.
 @return the font to use for the given style.
 */
- (UIFont *)fontForStyle:(NSString *)textStyle;

/**
 @param style the style whose color should be returned.
 @return the color to use for the given style.
 */
- (UIColor *)colorForStyle:(NSString *)style;

@end

/// The text style for the title text of the greeting view in Message Center.
extern NSString *const ApptentiveTextStyleHeaderTitle;

/// The text style for the message text of the greeting view in Message Center.
extern NSString *const ApptentiveTextStyleHeaderMessage;

/// The text style for the date lables in Message Center.
extern NSString *const ApptentiveTextStyleMessageDate;

/// The text style for the message sender text in Message Center.
extern NSString *const ApptentiveTextStyleMessageSender;

/// The text style for the message status text in Message Center.
extern NSString *const ApptentiveTextStyleMessageStatus;

/// The text style for the message center status text in Message Center.
extern NSString *const ApptentiveTextStyleMessageCenterStatus;

/// The text style for the survey description text.
extern NSString *const ApptentiveTextStyleSurveyInstructions;

/// The text style for buttons that make changes when tapped.
extern NSString *const ApptentiveTextStyleDoneButton;

/// The text style for buttons that cancel or otherwise don't make changes when tapped.
extern NSString *const ApptentiveTextStyleButton;

/// The text style for the the submit button on Surveys.
extern NSString *const ApptentiveTextStyleSubmitButton;

/// The text style for text input fields.
extern NSString *const ApptentiveTextStyleTextInput;


/// The background color for headers in Message Center and Surveys.
extern NSString *const ApptentiveColorHeaderBackground;

/// The background color for the footer in Surveys.
extern NSString *const ApptentiveColorFooterBackground;

/// The foreground color for text and borders indicating a failure of validation or sending.
extern NSString *const ApptentiveColorFailure;

/// The foreground color for borders in Message Center and Surveys.
extern NSString *const ApptentiveColorSeparator;

/// The background color for cells in Message Center and Surveys.
extern NSString *const ApptentiveColorBackground;

/// The background color for table- and collection views.
extern NSString *const ApptentiveColorCollectionBackground;

/// The background color for text input fields.
extern NSString *const ApptentiveColorTextInputBackground;

/// The color for text input placeholder text.
extern NSString *const ApptentiveColorTextInputPlaceholder;

/// The background color for message cells in Message Center.
extern NSString *const ApptentiveColorMessageBackground;

/// The background color for reply cells in Message Center.
extern NSString *const ApptentiveColorReplyBackground;

/// The background color for context cells in Message Center.
extern NSString *const ApptentiveColorContextBackground;

NS_ASSUME_NONNULL_END
