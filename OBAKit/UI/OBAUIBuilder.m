//
//  OBAUIBuilder.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/12/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAUIBuilder.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/UILabel+OBAAdditions.h>
@import QuartzCore;
@import Masonry;

@implementation OBAUIBuilder

+ (UILabel*)label {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.numberOfLines = 1;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.8f;
    return label;
}

+ (UIView*)footerViewWithText:(NSString*)text maximumWidth:(CGFloat)width {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake([OBATheme defaultPadding], [OBATheme defaultPadding], width - (2 * [OBATheme defaultPadding]), 10)];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [OBATheme footnoteFont];
    label.text = text;
    [label oba_resizeHeightToFit];

    UIView *wrapper = [[UIView alloc] initWithFrame:CGRectInset(label.frame, -[OBATheme defaultPadding], -[OBATheme defaultPadding])];
    [wrapper addSubview:label];

    return wrapper;
}

+ (UIView*)lineView {
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [lineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@1);
    }];

    return lineView;
}

+ (UIButton*)contextMenuButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *ellipsis = [UIImage imageNamed:@"ellipsis_button"];
    [button setImage:ellipsis forState:UIControlStateNormal];
    button.tintColor = [OBATheme OBAGreenWithAlpha:0.7f];
    button.accessibilityLabel = NSLocalizedString(@"classic_departure_cell.context_button_accessibility_label", @"This is the ... button shown on the right side of a departure cell. Tapping it shows a menu with more options.");

    return button;
}

+ (UIBarButtonItem*)wrappedImageButton:(UIImage*)image accessibilityLabel:(NSString*)label target:(id)target action:(SEL)action {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    button.tintColor = UIColor.darkGrayColor;
    [button setImage:image forState:UIControlStateNormal];
    button.imageEdgeInsets = [OBATheme defaultEdgeInsets];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    return barButtonItem;

}

@end
