//
//  OBATheme.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/11/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBATheme.h"

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
    UIColor *tintColor = OBAGREEN;
    [[UINavigationBar appearance] setTintColor:tintColor];
    [[UISearchBar appearance] setTintColor:tintColor];
    [[UISegmentedControl appearance] setTintColor:tintColor];
    [[UITabBar appearance] setTintColor:tintColor];
    [[UITextField appearance] setTintColor:tintColor];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateSelected];
}

#pragma mark - UIFont

+ (UIFont*)bodyFont {
    if (!_bodyFont) {
        _bodyFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    }
    return _bodyFont;
}

+ (UIFont*)boldBodyFont {
    if (!_boldBodyFont) {
        UIFontDescriptor *bodyFontDesciptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        UIFontDescriptor *boldBodyFontDescriptor = [bodyFontDesciptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        _boldBodyFont = [UIFont fontWithDescriptor:boldBodyFontDescriptor size:0.0];
    }
    return _boldBodyFont;
}

+ (UIFont*)titleFont {
    if (!_titleFont) {
        _titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
    }
    return _titleFont;
}

+ (UIFont*)subtitleFont {
    if (!_subtitleFont) {
        _subtitleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    }
    return _subtitleFont;
}

+ (UIFont*)footnoteFont {
    if (!_footnoteFont) {
        _footnoteFont = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    }
    return _footnoteFont;
}

+ (UIFont*)boldFootnoteFont {
    if (!_boldFootnoteFont) {
        UIFontDescriptor *fontDesciptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleFootnote];
        UIFontDescriptor *boldFontDescriptor = [fontDesciptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        _boldFootnoteFont = [UIFont fontWithDescriptor:boldFontDescriptor size:0.0];
    }
    return _boldFootnoteFont;
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

+ (UIColor*)nonOpaquePrimaryColor {
    return [self colorWithRed:152 green:216 blue:69 alpha:0.8f];
}

+ (UIColor*)backgroundColor {
    return [self colorWithRed:235 green:242 blue:224 alpha:1.f];
}

+ (UIColor*)mapBookmarkTintColor {
    return [OBATheme colorWithRed:255 green:200 blue:39 alpha:1.f];
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