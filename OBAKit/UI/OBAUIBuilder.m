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

@end
