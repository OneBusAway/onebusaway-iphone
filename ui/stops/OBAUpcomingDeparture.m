//
//  OBAUpcomingDeparture.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAUpcomingDeparture.h"

@implementation OBAUpcomingDeparture

- (instancetype)initWithDepartureDate:(NSDate*)departureDate departureStatus:(OBADepartureStatus)departureStatus {
    self = [super init];
    if (self) {
        _departureDate = [departureDate copy];
        _departureStatus = departureStatus;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OBAUpcomingDeparture *departure = [[OBAUpcomingDeparture alloc] init];
    departure->_departureDate = [_departureDate copyWithZone:zone];
    departure->_departureStatus = _departureStatus;
    return departure;
}

@end
