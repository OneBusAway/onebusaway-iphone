//
//  OBARotatingButton.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/1/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBARotatingButton.h"
@import OBAKit;

@implementation OBARotatingButton

+ (instancetype)rotatingButton {
    OBARotatingButton *button = [OBARotatingButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"disclosure_button"] forState:UIControlStateNormal];
    return button;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
    CGAffineTransform transform = selected ? CGAffineTransformMakeRotation(M_PI_2) : CGAffineTransformIdentity;
#pragma clang diagnostic pop

    [OBAAnimation performAnimations:^{
        self.transform = transform;
    }];
}

@end
