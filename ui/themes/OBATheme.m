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
static UIFont *_headlineFont = nil;
static UIFont *_footnoteFont = nil;

@implementation OBATheme

#pragma mark - Helpers

+ (void)resetTheme {
    _bodyFont = nil;
    _boldBodyFont = nil;
    _headlineFont = nil;
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

+ (UIFont*)headlineFont {
    if (!_headlineFont) {
        _headlineFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    }
    return _headlineFont;
}

+ (UIFont*)footnoteFont {
    if (!_footnoteFont) {
        _footnoteFont = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    }
    return _footnoteFont;
}

#pragma mark - UIColor

+ (UIColor*)backgroundColor {
    return [UIColor colorWithRed:0.92f green:0.95f blue:0.88f alpha:0.67f];
}

+ (UIColor*)onTimeDepartureColor {
    return [UIColor colorWithRed:0.f green:0.478f blue:0.f alpha:1.f];
}

#pragma mark - Pixels, err points

+ (CGFloat)defaultPadding {
    return 8.f;
}

@end
