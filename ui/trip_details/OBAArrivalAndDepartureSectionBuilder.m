//
//  OBAArrivalAndDepartureSectionBuilder.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAArrivalAndDepartureSectionBuilder.h"

@implementation OBAArrivalAndDepartureSectionBuilder

+ (OBAClassicDepartureRow *)createDepartureRow:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    NSString *dest = arrivalAndDeparture.tripHeadsign.capitalizedString;
    OBAClassicDepartureRow *departureRow = [[OBAClassicDepartureRow alloc] initWithRouteName:arrivalAndDeparture.bestAvailableName destination:dest departsAt:[NSDate dateWithTimeIntervalSince1970:(arrivalAndDeparture.bestDepartureTime / 1000)] statusText:[arrivalAndDeparture statusText] departureStatus:[arrivalAndDeparture departureStatus] action:nil];

    return departureRow;
}

@end
