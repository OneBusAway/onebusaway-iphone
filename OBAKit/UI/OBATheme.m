//
//  OBATheme.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/11/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import <OBAKit/OBATheme.h>

static CGFloat const kMaxFontSize = 24.f;

static UIFont *_headlineFont = nil;
static UIFont *_subheadFont = nil;
static UIFont *_boldSubheadFont = nil;
static UIFont *_bodyFont = nil;
static UIFont *_boldBodyFont = nil;
static UIFont *_largeTitleFont = nil;
static UIFont *_titleFont = nil;
static UIFont *_subtitleFont = nil;
static UIFont *_footnoteFont = nil;
static UIFont *_boldFootnoteFont = nil;
static UIFont *_italicFootnoteFont = nil;

@implementation OBATheme

#pragma mark - Helpers

+ (void)resetTheme {
    _headlineFont = nil;
    _subheadFont = nil;
    _bodyFont = nil;
    _boldBodyFont = nil;
    _largeTitleFont = nil;
    _titleFont = nil;
    _subtitleFont = nil;
    _footnoteFont = nil;
    _boldFootnoteFont = nil;
    _italicFootnoteFont = nil;
}

#pragma mark - Appearance Proxies

+ (void)setAppearanceProxies {
    UIColor *tintColor = [self OBAGreen];
    [[UIWindow appearance] setTintColor:tintColor];
    [[UINavigationBar appearance] setTintColor:tintColor];
    [[UISearchBar appearance] setTintColor:tintColor];
    [[UISegmentedControl appearance] setTintColor:tintColor];
    [[UITabBar appearance] setTintColor:tintColor];
    [[UITextField appearance] setTintColor:tintColor];
    [[UIButton appearance] setTintColor:tintColor];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: tintColor } forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateSelected];
    [[UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[UINavigationBar.class]] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor blackColor] } forState:UIControlStateNormal];

    [[UITableViewCell appearance] setPreservesSuperviewLayoutMargins:YES];
    [[[UITableViewCell appearance] contentView] setPreservesSuperviewLayoutMargins:YES];

    // Per:
    // https://github.com/Instagram/IGListKit/blob/master/Guides/Working%20with%20UICollectionView.md
    [[UICollectionView appearance] setPrefetchingEnabled:NO];
}

#pragma mark - UIFont

+ (UIFont*)headlineFont {
    if (!_headlineFont) {
        _headlineFont = [self fontWithTextStyle:UIFontTextStyleHeadline];
    }
    return _headlineFont;
}

+ (UIFont*)subheadFont {
    if (!_subheadFont) {
        _subheadFont = [self fontWithTextStyle:UIFontTextStyleSubheadline];
    }
    return _subheadFont;
}

+ (UIFont*)boldSubheadFont {
    if (!_boldSubheadFont) {
        _boldSubheadFont = [self boldFontWithTextStyle:UIFontTextStyleSubheadline];
    }
    return _boldSubheadFont;
}

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

+ (UIFont*)largeTitleFont {
    if (!_largeTitleFont) {
        _largeTitleFont = [self fontWithTextStyle:UIFontTextStyleTitle1];
    }
    return _largeTitleFont;
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

+ (UIFont*)italicFootnoteFont {
    if (!_italicFootnoteFont) {
        _italicFootnoteFont = [self italicFontWithTextStyle:UIFontTextStyleFootnote];
    }
    return _italicFootnoteFont;
}

#pragma mark - Private Font Helpers

+ (UIFont*)fontWithTextStyle:(NSString*)textStyle {
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
    return [UIFont fontWithDescriptor:descriptor size:MIN(descriptor.pointSize, kMaxFontSize)];
}

+ (UIFont*)boldFontWithTextStyle:(NSString*)textStyle {
    return [self fontWithTextStyle:textStyle symbolicTraits:UIFontDescriptorTraitBold];
}

+ (UIFont*)italicFontWithTextStyle:(NSString*)textStyle {
    return [self fontWithTextStyle:textStyle symbolicTraits:UIFontDescriptorTraitItalic];
}

+ (UIFont*)fontWithTextStyle:(NSString*)textStyle symbolicTraits:(UIFontDescriptorSymbolicTraits)symbolicTraits {
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:textStyle];
    UIFontDescriptor *augmentedDescriptor = [descriptor fontDescriptorWithSymbolicTraits:symbolicTraits];
    return [UIFont fontWithDescriptor:augmentedDescriptor size:MIN(augmentedDescriptor.pointSize, kMaxFontSize)];
}

#pragma mark - Colors

+ (UIColor*)mapTableBackgroundColor {
    return [self colorWithRed:238 green:238 blue:238 alpha:1.f];
}

+ (BOOL)useHighContrastUI {
    return UIAccessibilityDarkerSystemColorsEnabled() || UIAccessibilityIsReduceTransparencyEnabled();
}

+ (UIColor*)colorWithRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((CGFloat)red / 255.f) green:((CGFloat)green / 255.f) blue:((CGFloat)blue / 255.f) alpha:alpha];
}

+ (UIColor*)darkDisabledColor {
    return [UIColor darkGrayColor];
}

+ (UIColor*)lightDisabledColor {
    return [UIColor grayColor];
}

+ (UIColor*)borderColor {
    return [OBATheme colorWithRed:177 green:177 blue:177 alpha:0.7f];
}

+ (UIColor*)textColor {
    return [UIColor blackColor];
}

+ (UIColor*)scheduledDepartureColor {
    return self.darkDisabledColor;
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

+ (UIColor*)mapUserLocationColor {
    return [OBATheme colorWithRed:38 green:122 blue:255 alpha:1.f];
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

+ (UIColor*)userLocationFillColor {
    return [self colorWithRed:25 green:131 blue:247 alpha:1.f];
}

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

+ (UIColor*)darkBlurLabelTextColor {
    if (UIAccessibilityIsReduceTransparencyEnabled()) {
        return [UIColor whiteColor];
    }
    else {
        return [UIColor blackColor];
    }
}

+ (UIColor*)tableViewSeparatorLineColor {
    return [OBATheme colorWithRed:200 green:199 blue:204 alpha:1.f];
}

#pragma mark - Sizes

+ (CGFloat)defaultMargin {
    return 20.f;
}

+ (CGFloat)minimalPadding {
    return self.defaultPadding / 4.f;
}

+ (CGFloat)compactPadding {
    return self.defaultPadding / 2.f;
}

+ (CGFloat)defaultPadding {
    return 8.f;
}

+ (CGFloat)defaultCornerRadius {
    return [self compactPadding];
}

+ (CGFloat)compactCornerRadius {
    return [self minimalPadding];
}

+ (UIEdgeInsets)marginSizedEdgeInsets {
    return UIEdgeInsetsMake(self.defaultMargin, self.defaultMargin, self.defaultMargin, self.defaultMargin);
}


+ (UIEdgeInsets)defaultEdgeInsets {
    return UIEdgeInsetsMake([self defaultPadding], [self defaultPadding], [self defaultPadding], [self defaultPadding]);
}

+ (UIEdgeInsets)compactEdgeInsets {
    return UIEdgeInsetsMake([self compactPadding], [self compactPadding], [self compactPadding], [self compactPadding]);
}

+ (UIEdgeInsets)hoverBarImageInsets {
    return self.defaultEdgeInsets;
}

@end
