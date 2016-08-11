//
//  UILabel+OBAAdditions.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/12/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "UILabel+OBAAdditions.h"

@implementation UILabel (OBAAdditions)

- (void)oba_resizeHeightToFit {

    CGRect calculatedRect = [self.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.frame), CGFLOAT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName: self.font}
                                                     context:nil];

    CGRect labelFrame = self.frame;
    labelFrame.size.height = CGRectGetHeight(calculatedRect);
    self.frame = labelFrame;
}

@end
