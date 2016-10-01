//
//  OBAArrivalAndDepartureSectionBuilder.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAArrivalAndDepartureSectionBuilder.h"

@implementation OBAArrivalAndDepartureSectionBuilder

+ (nullable OBADepartureRow *)createDepartureRow:(NSArray<OBAArrivalAndDepartureV2*>*)arrivalAndDepartures {
    OBAGuard(arrivalAndDepartures.count > 0) else {
        return nil;
    }

    OBADepartureRow *row = [[OBADepartureRow alloc] initWithAction:nil];
    OBAArrivalAndDepartureV2 *dep = arrivalAndDepartures.firstObject;

    row.routeName = dep.bestAvailableName;
    row.destination = dep.tripHeadsign;
    row.upcomingDepartures = [arrivalAndDepartures valueForKey:NSStringFromSelector(@selector(bestDeparture))];
    row.statusText = dep.statusText;
    row.departureStatus = dep.departureStatus;

    return row;
}

@end
