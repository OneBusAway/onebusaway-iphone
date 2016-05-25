//
//  OBADateHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/11/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OBATripDetailsV2;
@class OBATripStopTimeV2;

NS_ASSUME_NONNULL_BEGIN

@interface OBADateHelpers : NSObject
+ (NSString*)formatShortTimeNoDate:(NSDate*)date;
+ (NSDate *)getTripStopTimeAsDate:(OBATripStopTimeV2*)stopTime tripDetails:(OBATripDetailsV2*)tripDetails;
@end

NS_ASSUME_NONNULL_END