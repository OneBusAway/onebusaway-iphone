//
//  OBAStrings.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBAStrings : NSObject

/**
 The text 'Cancel'.
 */
+ (NSString*)cancel;

/**
 The text 'Close'.
 */
+ (NSString*)close;

/**
 The text 'Delete'.
 */
+ (NSString*)delete;

/**
 The text 'Dismiss'. Used on alerts.
 iOS tends to use 'Dismiss' instead of 'OK' on alerts that the user isn't actually agreeing to.
 */
+ (NSString*)dismiss;

/**
 The text 'Edit'.
 */
+ (NSString*)edit;

/**
 The text 'Error'.
 */
+ (NSString*)error;

/**
 Generic error used for situations that shouldn't happen. Asks user to contact us.
 */
+ (NSString*)inexplicableErrorPleaseContactUs;

/**
 The text 'OK'.
 */
+ (NSString*)ok;

/**
 The text 'Save'.
 */
+ (NSString*)save;

/**
 The explanatory text displayed when a non-realtime trip is displayed on-screen.
 */
+ (NSString*)scheduledDepartureExplanation;

/**
 The word 'yesterday'
 */
+ (NSString*)yesterday;

/**
 Created an attributed string with a prepended image.

 @param image An image that will precede the string.
 @param string A string
 @return An attributed string with an image preceding it. Suitable for rendering in a label.
 */
+ (nullable NSAttributedString*)attributedStringWithPrependedImage:(UIImage*)image string:(NSString*)string;

/**
 Created an attributed string with a prepended image.

 @param image  An image that will precede the string.
 @param string A string
 @param color  The color for the text and image. Defaults to white if unspecified.
 @return An attributed string with an image preceding it. Suitable for rendering in a label.
 */
+ (nullable NSAttributedString*)attributedStringWithPrependedImage:(UIImage*)image string:(NSString*)string color:(nullable UIColor*)color;

@end

NS_ASSUME_NONNULL_END
