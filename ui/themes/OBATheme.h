//
//  OBATheme.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/11/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBATheme : NSObject

/**
 * Called when, e.g., the user's contrast or font size choices
 * change at the system level.
 */
+ (void)resetTheme;

// Fonts

/**
 * The appropriate font to use for body or label text. Resizes based upon
 * the user's chosen font sizes at the system level.
 */
+ (UIFont*)bodyFont;

/**
 * The appropriate font to use for footer text, or a sidenote.
 * Please use sparingly.
 */
+ (UIFont*)footnoteFont;

/**
 * The appropriate font to use for footer text, or a sidenote, but bolded.
 * Please use sparingly.
 */
+ (UIFont*)boldFootnoteFont;

/**
 * A bold variant of the appropriate font to use for body or label text.
 * Resizes based upon the user's chosen font sizes at the system level.
 */
+ (UIFont*)boldBodyFont;

/**
 * The largest title font.
 */
+ (UIFont*)titleFont;

/**
 * A smaller title font.
 */
+ (UIFont*)subtitleFont;


// Colors

/**
 Creates a UIColor with color values expressed in more typical 0-255 fashion.

 @param red   Red component: 0-255.
 @param green Green component: 0-255.
 @param blue  Blue component: 0-255.
 @param alpha Alpha component: 0-1.

 @return A UIColor
 */
+ (UIColor*)colorWithRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue alpha:(CGFloat)alpha;

/**
 The standard highlight color with a less-than-100% opacity. By default, this is a dark green color.

 @return A UIColor.
 */
+ (UIColor*)nonOpaquePrimaryColor;

/**
 * The default background color for non-white pages. By default, this is a dark green color.
 */
+ (UIColor*)backgroundColor;

/**
 * The text color used to indicate that the bus is on time for a given stop.
 */
+ (UIColor*)onTimeDepartureColor;

/**
 The text color used to indicate that the bus will depart early. Usually red.
 */
+ (UIColor*)earlyDepartureColor;

/**
 The text color used to indicate that the bus will depart late. Usually blue.
 */
+ (UIColor*)delayedDepartureColor;

// Pixels (err, points)

/**
 Half of the default padding. Used in situations where a tighter fit is necessary.
 */
+ (CGFloat)halfDefaultPadding;

/**
 * The default vertical and horizontal padding in px.
 */
+ (CGFloat)defaultPadding;

/**
 The value of +[OBATheme defaultPadding] in the form of UIEdgeInsets.
 */
+ (UIEdgeInsets)defaultEdgeInsets;
@end