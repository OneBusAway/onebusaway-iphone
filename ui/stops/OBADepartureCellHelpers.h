//
//  OBADepartureCellHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OBAKit/OBAKit.h>

@interface OBADepartureCellHelpers : NSObject

/**
 Creates a human-readable attributed string that describes when the next departure for a route will occur.
 e.g. "9:16 PM - 4 min late"

 @param nextDepartureTime e.g. 9:41AM
 @param statusText        e.g. 4 min late
 @param departureStatus   Delayed, on time, early

 @return An attributed string
 */
+ (NSAttributedString*)attributedDepartureTime:(NSString*)nextDepartureTime statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus;
+ (UIColor*)colorForStatus:(OBADepartureStatus)status;
+ (UIFont*)fontForStatus:(OBADepartureStatus)status;

@end
