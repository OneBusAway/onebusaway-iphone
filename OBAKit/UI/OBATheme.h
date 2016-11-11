//
//  OBATheme.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/11/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

@import UIKit;

@interface OBATheme : NSObject

/**
 * Called when, e.g., the user's contrast or font size choices
 * change at the system level.
 */
+ (void)resetTheme;

// Appearance Proxies

/**
 Sets tint colors, title text attributes, etc. for UIKit controls.
 */
+ (void)setAppearanceProxies;

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
 * Returns YES if the user has enabled darker system colors or reduced transparency.
 */
+ (BOOL)useHighContrastUI;

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
 Formerly known as OBAGREEN.
 */
+ (UIColor*)OBAGreen;

/**
 Formerly known as OBAGREENWITHALPHA.
 */
+ (UIColor*)OBAGreenWithAlpha:(CGFloat)alpha;

/**
 Formerly known as OBAGREENBACKGROUND. Very, very pale green. Semi-transparent.
 */
+ (UIColor*)OBAGreenBackground;

/**
 Formerly known as OBADARKGREEN.
 */
+ (UIColor*)OBADarkGreen;

/**
 Use this for UI elements that are not enabled or non-interactable.
 */
+ (UIColor*)darkDisabledColor;

/**
 Use this for UI elements that are not enabled or non-interactable.
 */
+ (UIColor*)lightDisabledColor;


/**
 Used for border lines on containers and the like. The same color that is used on the bottom
 of a navigation bar, for instance.
 */
+ (UIColor*)borderColor;

/**
 Standard text color.
 */
+ (UIColor*)textColor;

/**
 Use this when a control changes value on screen and you want to highlight
 its changed value for the user.
 */
+ (UIColor*)propertyChangedColor;

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
 Used to tint bookmarks on the map view.
*/
+ (UIColor*)mapBookmarkTintColor;

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

/**
 Table view section header background color.
 */
+ (UIColor*)tableViewSectionHeaderBackgroundColor;

/**
 The color used on a label's textColor property when the label sits on a dark blurred background.
 */
+ (UIColor*)darkBlurLabelTextColor;

// Pixels (err, points)

/**
 Half of the default padding. Used in situations where a tighter fit is necessary.
 */
+ (CGFloat)compactPadding;

/**
 * The default vertical and horizontal padding in px.
 */
+ (CGFloat)defaultPadding;

/**
 The default corner radius to apply to views that require rounded edges.
 */
+ (CGFloat)defaultCornerRadius;

/**
 The value of +[OBATheme defaultPadding] in the form of UIEdgeInsets.
 */
+ (UIEdgeInsets)defaultEdgeInsets;

/**
 The value of +[OBATheme compactPadding] in the form of UIEdgeInsets.
 */
+ (UIEdgeInsets)compactEdgeInsets;
@end
