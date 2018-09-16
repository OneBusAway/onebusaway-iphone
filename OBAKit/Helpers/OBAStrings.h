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
@property(class,nonatomic,copy,readonly) NSString *cancel;

/**
 The text 'Close'.
 */
@property(class,nonatomic,copy,readonly) NSString *close;

/**
 The text 'Continue'.
 */
@property(class,nonatomic,copy,readonly) NSString *continueString;

/**
 The text 'Delete'.
 */
@property(class,nonatomic,copy,readonly) NSString *delete;

/**
 The text 'Dismiss'. Used on alerts.
 iOS tends to use 'Dismiss' instead of 'OK' on alerts that the user isn't actually agreeing to.
 */
@property(class,nonatomic,copy,readonly) NSString *dismiss;

/**
 The text 'Edit'.
 */
@property(class,nonatomic,copy,readonly) NSString *edit;

/**
 The text 'Error'.
 */
@property(class,nonatomic,copy,readonly) NSString *error;

/**
 Generic error used for situations that shouldn't happen. Asks user to contact us.
 */
@property(class,nonatomic,copy,readonly) NSString *inexplicableErrorPleaseContactUs;

/**
 The text 'OK'.
 */
@property(class,nonatomic,copy,readonly) NSString *ok;

/**
 The text 'Save'.
 */
@property(class,nonatomic,copy,readonly) NSString *save;

/**
 The explanatory text displayed when a non-realtime trip is displayed on-screen.
 */
@property(class,nonatomic,copy,readonly) NSString *scheduledDepartureExplanation;

/**
 The word 'yesterday'
 */
@property(class,nonatomic,copy,readonly) NSString *yesterday;

/**
 The word 'never'
 */
@property(class,nonatomic,copy,readonly) NSString *never;

/**
 The text 'Read More…' (note that is an ellipsis, not three dots…)
 */
@property(class,nonatomic,copy,readonly) NSString *readMore;

/**
 The word 'Refresh', like a synonym for 'Reload'.
 */
@property(class,nonatomic,copy,readonly) NSString *refresh;

/**
 As in 'actively updating content'.
 */
@property(class,nonatomic,copy,readonly) NSString *updating;

/**
 Learn More
 */
@property(class,nonatomic,copy,readonly) NSString *learnMore;

/**
 Not Found
 */
@property(class,nonatomic,copy,readonly) NSString *notFound;

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
