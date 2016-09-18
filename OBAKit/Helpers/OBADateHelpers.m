//
//  OBADateHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <OBAKit/OBADateHelpers.h>
#import <OBAKit/OBATripDetailsV2.h>
#import <OBAKit/OBATripStopTimeV2.h>

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

+ (NSDate *)getTripStopTimeAsDate:(OBATripStopTimeV2*)stopTime tripDetails:(OBATripDetailsV2*)tripDetails {
    NSInteger departureTime = stopTime.departureTime;
    long long serviceDate = 0;
    NSInteger scheduleDeviation = 0;

    OBATripStatusV2 *status = tripDetails.status;

    if (status) {
        serviceDate = status.serviceDate;
        scheduleDeviation = status.scheduleDeviation;
    }
    else {
        serviceDate = tripDetails.serviceDate;
        scheduleDeviation = 0;
    }

    NSTimeInterval interval = serviceDate / 1000 + departureTime + scheduleDeviation;

    return [NSDate dateWithTimeIntervalSince1970:interval];
}
@end
