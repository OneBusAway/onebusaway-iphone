//
//  OBADateHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

@import Foundation;

@class OBATripDetailsV2;
@class OBATripStopTimeV2;

NS_ASSUME_NONNULL_BEGIN

@interface OBADateHelpers : NSObject
+ (NSString*)formatShortTimeNoDate:(NSDate*)date;
+ (NSString*)formatShortTimeShortDate:(NSDate*)date;
+ (NSString*)formatNoTimeShortDate:(NSDate*)date;

+ (NSDate *)getTripStopTimeAsDate:(OBATripStopTimeV2*)stopTime tripDetails:(OBATripDetailsV2*)tripDetails;
+ (NSString*)formatMinutesUntilDate:(NSDate*)date;

/**
 Creates a date from the provided millisecond value.

 @param milliseconds Milliseconds since January 1, 1970

 @return An NSDate
 */
+ (NSDate*)dateWithMillisecondsSince1970:(long long)milliseconds;
@end

NS_ASSUME_NONNULL_END
