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
    NSString *routeName = arrivalAndDeparture.bestAvailableName;
    NSString *destination = arrivalAndDeparture.tripHeadsign;
    NSDate *departsAt = [NSDate dateWithTimeIntervalSince1970:(arrivalAndDeparture.bestDepartureTime / 1000)];
    NSString *statusText = [arrivalAndDeparture statusText];
    OBADepartureStatus departureStatus = [arrivalAndDeparture departureStatus];

    return [[OBAClassicDepartureRow alloc] initWithRouteName:routeName destination:destination departsAt:departsAt statusText:statusText departureStatus:departureStatus action:nil];
}

@end
