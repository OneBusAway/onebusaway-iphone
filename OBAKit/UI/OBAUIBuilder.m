//
//  OBAUIBuilder.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/12/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAUIBuilder.h"

@implementation OBAUIBuilder

+ (UILabel*)label {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.numberOfLines = 1;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.8f;
    return label;
}
@end
