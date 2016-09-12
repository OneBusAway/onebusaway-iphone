//
//  OBATheme.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/11/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBATheme.h"

static CGFloat const kMaxFontSize = 24.f;

static UIFont *_bodyFont = nil;
static UIFont *_boldBodyFont = nil;
static UIFont *_titleFont = nil;
static UIFont *_subtitleFont = nil;
static UIFont *_footnoteFont = nil;
static UIFont *_boldFootnoteFont = nil;

@implementation OBATheme

#pragma mark - Helpers

+ (void)resetTheme {
    _bodyFont = nil;
    _boldBodyFont = nil;
    _titleFont = nil;
    _subtitleFont = nil;
    _footnoteFont = nil;
    _boldFootnoteFont = nil;
}

#pragma mark - Appearance Proxies

+ (void)setAppearanceProxies {
    UIColor *tintColor = [self OBAGreen];
    [[UINavigationBar appearance] setTintColor:tintColor];
    [[UISearchBar appearance] setTintColor:tintColor];
    [[UISegmentedControl appearance] setTintColor:tintColor];
    [[UITabBar appearance] setTintColor:tintColor];
    [[UITextField appearance] setTintColor:tintColor];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateSelected];
    [[UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[UINavigationBar.class]] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor blackColor] } forState:UIControlStateNormal];
}

#pragma mark - UIFont

+ (UIFont*)bodyFont {
    if (!_bodyFont) {
        _bodyFont = [self fontWithTextStyle:UIFontTextStyleBody];
    }
    return _bodyFont;
}

+ (UIFont*)boldBodyFont {
    if (!_boldBodyFont) {
        _boldBodyFont = [self boldFontWithTextStyle:UIFontTextStyleBody];
    }
    return _boldBodyFont;
}

+ (UIFont*)titleFont {
    if (!_titleFont) {
        _titleFont = [self fontWithTextStyle:UIFontTextStyleTitle2];
    }
    return _titleFont;
}

+ (UIFont*)subtitleFont {
    if (!_subtitleFont) {
        _subtitleFont = [self fontWithTextStyle:UIFontTextStyleTitle3];
    }
    return _subtitleFont;
}

+ (UIFont*)footnoteFont {
    if (!_footnoteFont) {
        _footnoteFont = [self fontWithTextStyle:UIFontTextStyleFootnote];
    }
    return _footnoteFont;
}

+ (UIFont*)boldFootnoteFont {
    if (!_boldFootnoteFont) {
        _boldFootnoteFont = [self boldFontWithTextStyle:UIFontTextStyleFootnote];
    }
    return _boldFootnoteFont;
}

#pragma mark - Private Font Helpers

+ (UIFont*)fontWithTextStyle:(NSString*)textStyle {
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
    return [UIFont fontWithDescriptor:descriptor size:MIN(descriptor.pointSize, kMaxFontSize)];
}

+ (UIFont*)boldFontWithTextStyle:(NSString*)textStyle {
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
    UIFontDescriptor *boldDescriptor = [descriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    return [UIFont fontWithDescriptor:boldDescriptor size:MIN(boldDescriptor.pointSize, kMaxFontSize)];
}

#pragma mark - UIColor

+ (UIColor*)colorWithRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((CGFloat)red / 255.f) green:((CGFloat)green / 255.f) blue:((CGFloat)blue / 255.f) alpha:alpha];
}

+ (UIColor*)darkDisabledColor {
    return [UIColor darkGrayColor];
}

+ (UIColor*)lightDisabledColor {
    return [UIColor grayColor];
}

+ (UIColor*)textColor {
    return [UIColor blackColor];
}

+ (UIColor*)propertyChangedColor {
    return [OBATheme colorWithRed:255 green:255 blue:128 alpha:0.7f];
}

+ (UIColor*)nonOpaquePrimaryColor {
    return [self colorWithRed:152 green:216 blue:69 alpha:0.8f];
}

+ (UIColor*)backgroundColor {
    return [self colorWithRed:235 green:242 blue:224 alpha:1.f];
}

+ (UIColor*)mapBookmarkTintColor {
    return [OBATheme colorWithRed:255 green:200 blue:39 alpha:1.f];
}

#pragma mark - Brand Colors

+ (UIColor*)OBAGreen {
    return [self colorWithRed:121 green:171 blue:55 alpha:1.f];
}

+ (UIColor*)OBAGreenBackground {
    return [self colorWithRed:242 green:242 blue:224 alpha:.67f];
}

+ (UIColor*)OBAGreenWithAlpha:(CGFloat)alpha {
    return [[self OBAGreen] colorWithAlphaComponent:alpha];
}

+ (UIColor*)OBADarkGreen {
    return [self colorWithRed:51 green:102 blue:0 alpha:1.f];
}

#pragma mark - Named Colors

+ (UIColor*)onTimeDepartureColor {
    return [UIColor colorWithRed:0.f green:0.478f blue:0.f alpha:1.f];
}

+ (UIColor*)earlyDepartureColor {
    return [UIColor redColor];
}

+ (UIColor*)delayedDepartureColor {
    return [UIColor blueColor];
}

+ (UIColor*)tableViewSectionHeaderBackgroundColor {
    return [OBATheme colorWithRed:247.f green:247.f blue:247.f alpha:1.f];
}

#pragma mark - Pixels, err points

+ (CGFloat)compactPadding {
    return self.defaultPadding / 2.f;
}

+ (CGFloat)defaultPadding {
    return 8.f;
}

+ (CGFloat)defaultCornerRadius {
    return [self compactPadding];
}

+ (UIEdgeInsets)defaultEdgeInsets {
    return UIEdgeInsetsMake([self defaultPadding], [self defaultPadding], [self defaultPadding], [self defaultPadding]);
}

+ (UIEdgeInsets)compactEdgeInsets {
    return UIEdgeInsetsMake([self compactPadding], [self compactPadding], [self compactPadding], [self compactPadding]);
}

@end
