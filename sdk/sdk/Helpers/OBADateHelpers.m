//
//  OBADateHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBADateHelpers.h"

@implementation OBADateHelpers

+ (NSString*)formatShortTimeNoDate:(NSDate*)date
{
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.timeStyle = NSDateFormatterShortStyle;
        formatter.dateStyle = NSDateFormatterNoStyle;
    });

    return [formatter stringFromDate:date];
}

@end
