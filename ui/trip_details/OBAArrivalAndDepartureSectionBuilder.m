//
//  OBAArrivalAndDepartureSectionBuilder.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAArrivalAndDepartureSectionBuilder.h"

@implementation OBAArrivalAndDepartureSectionBuilder

+ (OBADepartureRow *)createDepartureRow:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    OBAGuard(arrivalAndDeparture) else {
        return nil;
    }

    OBADepartureRow *row = [[OBADepartureRow alloc] initWithAction:nil];

    row.routeName = arrivalAndDeparture.bestAvailableName;
    row.destination = arrivalAndDeparture.tripHeadsign;
    row.departsAt = [NSDate dateWithTimeIntervalSince1970:(arrivalAndDeparture.bestDepartureTime / 1000)];
    row.statusText = [arrivalAndDeparture statusText];
    row.departureStatus = [arrivalAndDeparture departureStatus];

    row.cellReuseIdentifier = OBAClassicDepartureCellReuseIdentifier;

    return row;
}

@end
