//
//  OBAUpcomingDeparture.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAUpcomingDeparture.h>

@implementation OBAUpcomingDeparture

- (instancetype)initWithDepartureDate:(NSDate*)departureDate departureStatus:(OBADepartureStatus)departureStatus arrivalDepartureState:(OBAArrivalDepartureState)arrivalDepartureState {
    self = [super init];
    if (self) {
        _departureDate = [departureDate copy];
        _departureStatus = departureStatus;
        _arrivalDepartureState = arrivalDepartureState;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OBAUpcomingDeparture *departure = [[OBAUpcomingDeparture alloc] init];
    departure->_departureDate = [_departureDate copyWithZone:zone];
    departure->_departureStatus = _departureStatus;
    departure->_arrivalDepartureState = _arrivalDepartureState;

    return departure;
}

+ (NSArray<OBAUpcomingDeparture*>*)upcomingDeparturesFromArrivalsAndDepartures:(NSArray<OBAArrivalAndDepartureV2*>*)matchingDepartures {
    NSMutableArray *upcomingDepartures = [NSMutableArray array];
    for (OBAArrivalAndDepartureV2 *dep in matchingDepartures) {
        [upcomingDepartures addObject:[[OBAUpcomingDeparture alloc] initWithDepartureDate:dep.bestArrivalDepartureDate departureStatus:dep.departureStatus arrivalDepartureState:dep.arrivalDepartureState]];
    }
    return [NSArray arrayWithArray:upcomingDepartures];
}

@end
