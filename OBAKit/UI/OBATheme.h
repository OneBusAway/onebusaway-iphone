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
 * The appropriate font to use for headlines. Resizes based upon
 * the user's chosen font sizes at the system level.
 */
@property(class,nonatomic,copy,readonly) UIFont *headlineFont;

/**
 * The appropriate font to use for subheadlines. Resizes based upon
 * the user's chosen font sizes at the system level.
 */
@property(class,nonatomic,copy,readonly) UIFont *subheadFont;

/**
 * Bold variant of the appropriate font to use for subheadlines. Resizes
 * based upon the user's chosen font sizes at the system level.
 */
@property(class,nonatomic,copy,readonly) UIFont *boldSubheadFont;

/**
 * The appropriate font to use for body or label text. Resizes based upon
 * the user's chosen font sizes at the system level.
 */
@property(class,nonatomic,copy,readonly) UIFont *bodyFont;

/**
 * The appropriate font to use for footer text, or a sidenote.
 * Please use sparingly.
 */
@property(class,nonatomic,copy,readonly) UIFont *footnoteFont;

/**
 * The appropriate font to use for footer text, or a sidenote, but bolded.
 * Please use sparingly.
 */
@property(class,nonatomic,copy,readonly) UIFont *boldFootnoteFont;

/**
 * The appropriate font to use for footer text, or a sidenote, but italicized.
 * Please use sparingly.
 */
@property(class,nonatomic,copy,readonly) UIFont *italicFootnoteFont;

/**
 * A bold variant of the appropriate font to use for body or label text.
 * Resizes based upon the user's chosen font sizes at the system level.
 */
@property(class,nonatomic,copy,readonly) UIFont *boldBodyFont;

/**
 * The largest title font.
 */
@property(class,nonatomic,copy,readonly) UIFont *largeTitleFont;

/**
 * Title font.
 */
@property(class,nonatomic,copy,readonly) UIFont *titleFont;

/**
 * A smaller title font.
 */
@property(class,nonatomic,copy,readonly) UIFont *subtitleFont;


// Colors

/**
 * Returns YES if the user has enabled darker system colors or reduced transparency.
 */
@property(class,nonatomic,assign,readonly) BOOL useHighContrastUI;

/**
 Creates a UIColor with color values expressed in more typical 0-255 fashion.

 @param red   Red component: 0-255.
 @param green Green component: 0-255.
 @param blue  Blue component: 0-255.
 @param alpha Alpha component: 0-1.

 @return A UIColor
 */
+ (UIColor*)colorWithRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue alpha:(CGFloat)alpha;

@property(class,nonatomic,copy,readonly) UIColor *mapTableBackgroundColor;

/**
 Formerly known as OBAGREEN.
 */
@property(class,nonatomic,copy,readonly) UIColor *OBAGreen;

/**
 Formerly known as OBAGREENWITHALPHA.
 */
+ (UIColor*)OBAGreenWithAlpha:(CGFloat)alpha;

/**
 Formerly known as OBAGREENBACKGROUND. Very, very pale green. Semi-transparent.
 */
@property(class,nonatomic,copy,readonly) UIColor *OBAGreenBackground;

/**
 Formerly known as OBADARKGREEN.
 */
@property(class,nonatomic,copy,readonly) UIColor *OBADarkGreen;

/**
 Used for custom user annotation views.
 */
@property(class,nonatomic,copy,readonly) UIColor *userLocationFillColor;

/**
 Use this for UI elements that are not enabled or non-interactable.
 */
@property(class,nonatomic,copy,readonly) UIColor *darkDisabledColor;

/**
 Use this for UI elements that are not enabled or non-interactable.
 */
@property(class,nonatomic,copy,readonly) UIColor *lightDisabledColor;

/**
 Used for border lines on containers and the like. The same color that is used on the bottom
 of a navigation bar, for instance.
 */
@property(class,nonatomic,copy,readonly) UIColor *borderColor;

/**
 Standard text color.
 */
@property(class,nonatomic,copy,readonly) UIColor *textColor;

/**
 Color of arrivals/departures that are 'scheduled' (i.e. not real-time).
 */
@property(class,nonatomic,copy,readonly) UIColor *scheduledDepartureColor;

/**
 Use this when a control changes value on screen and you want to highlight
 its changed value for the user.
 */
@property(class,nonatomic,copy,readonly) UIColor *propertyChangedColor;

/**
 The standard highlight color with a less-than-100% opacity. By default, this is a dark green color.

 @return A UIColor.
 */
@property(class,nonatomic,copy,readonly) UIColor *nonOpaquePrimaryColor;

/**
 * The default background color for non-white pages. By default, this is a dark green color.
 */
@property(class,nonatomic,copy,readonly) UIColor *backgroundColor;

/**
 Used to tint bookmarks on the map view.
*/
@property(class,nonatomic,copy,readonly) UIColor *mapBookmarkTintColor;

/**
 The color used to highlight the user location annotation view on the map.
 */
@property(class,nonatomic,copy,readonly) UIColor *mapUserLocationColor;

/**
 * The text color used to indicate that the bus is on time for a given stop.
 */
@property(class,nonatomic,copy,readonly) UIColor *onTimeDepartureColor;

/**
 The text color used to indicate that the bus will depart early. Usually red.
 */
@property(class,nonatomic,copy,readonly) UIColor *earlyDepartureColor;

/**
 The text color used to indicate that the bus will depart late. Usually blue.
 */
@property(class,nonatomic,copy,readonly) UIColor *delayedDepartureColor;

/**
 Table view section header background color.
 */
@property(class,nonatomic,copy,readonly) UIColor *tableViewSectionHeaderBackgroundColor;

/**
 The color of the line that separates one table view cell from another.
 */
@property(class,nonatomic,copy,readonly) UIColor *tableViewSeparatorLineColor;

/**
 The color used on a label's textColor property when the label sits on a dark blurred background.
 */
@property(class,nonatomic,copy,readonly) UIColor *darkBlurLabelTextColor;

/**
 The size in points of the leading and trailing margins for content in view controllers. 20pt by default.
 */
@property(class,nonatomic,assign,readonly) CGFloat defaultMargin;

/**
 One quarter of the default padding. Use it on screens like the Today View widget.
 */
@property(class,nonatomic,assign,readonly) CGFloat minimalPadding;

/**
 Half of the default padding. Used in situations where a tighter fit is necessary.
 */
@property(class,nonatomic,assign,readonly) CGFloat compactPadding;

/**
 * The default vertical and horizontal padding in px.
 */
@property(class,nonatomic,assign,readonly) CGFloat defaultPadding;

/**
 The default corner radius to apply to views that require rounded edges.
 */
@property(class,nonatomic,assign,readonly) CGFloat defaultCornerRadius;

/**
 A more compact corner radius to apply to views that require rounded edges.
 */
@property(class,nonatomic,assign,readonly) CGFloat compactCornerRadius;

/**
 The value of +[OBATheme defaultMargin] in the form of UIEdgeInsets.
 */
@property(class,nonatomic,assign,readonly) UIEdgeInsets marginSizedEdgeInsets;

/**
 The value of +[OBATheme defaultPadding] in the form of UIEdgeInsets.
 */
@property(class,nonatomic,assign,readonly) UIEdgeInsets defaultEdgeInsets;

/**
 The value of +[OBATheme compactPadding] in the form of UIEdgeInsets.
 */
@property(class,nonatomic,assign,readonly) UIEdgeInsets compactEdgeInsets;

/**
 Default insets for images placed in UIButtons inside of a hover bar—our version of a FAB.
 */
@property(class,nonatomic,assign,readonly) UIEdgeInsets hoverBarImageInsets;

@end
