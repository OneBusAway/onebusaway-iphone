//
//  OBARotatingButton.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/1/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBARotatingButton.h"
#import "OBAAnimation.h"

@implementation OBARotatingButton

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];

    CGAffineTransform transform = selected ? CGAffineTransformMakeRotation(M_PI_2) : CGAffineTransformIdentity;

    [OBAAnimation performAnimations:^{
        self.transform = transform;
    }];
}

@end
