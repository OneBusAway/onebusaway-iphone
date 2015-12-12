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
 * A bold variant of the appropriate font to use for body or label text.
 * Resizes based upon the user's chosen font sizes at the system level.
 */
+ (UIFont*)boldBodyFont;

/**
 * Big, freeform title text. A 'headline,' if you will.
 */
+ (UIFont*)headlineFont;

// Colors

/**
 * The default background color for non-white pages. By default, this is a dark green color.
 */
+ (UIColor*)backgroundColor;

/**
 * The text color used to indicate that the bus is on time for a given stop.
 */
+ (UIColor*)onTimeDepartureColor;
@end
