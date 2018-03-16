//
//  OBADepartureCellHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;

#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBAUpcomingDeparture.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBADepartureCellHelpers : NSObject

/**
 Creates a human-readable attributed string that describes when the next departure for a route will occur.
 e.g. "9:16 PM - 4 min late"

 @param statusText e.g. 4 min late
 @param upcomingDeparture An object that encapsulates several pieces of data about this departure.
 @return An attributed string
 */
+ (NSAttributedString*)attributedDepartureTimeWithStatusText:(NSString*)statusText upcomingDeparture:(nullable OBAUpcomingDeparture*)upcomingDeparture;
+ (UIColor*)colorForStatus:(OBADepartureStatus)status;

/**
 Creates a string based upon the supplied ArrivalAndDeparture object that resembles the following:
 - arriving 3 min early
 - arriving 2 min late
 - arrived 2 min early
 - arrived 5 min late
 - arrived on time
 - arriving on time
 - scheduled arrival*
 - departing 5 min early
 - departing 1 min early
 - departed 3 min early
 - departed 2 min late
 - departed on time
 - departing on time
 - scheduled departure*

 @param arrivalAndDeparture The ArrivalAndDeparture object used to generate the string
 @return The arrival/departure status string
 */
+ (nullable NSString*)statusTextForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;
@end

NS_ASSUME_NONNULL_END
