//
//  OBAArrivalAndDepartureSectionBuilder.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAArrivalAndDepartureSectionBuilder.h"

@interface OBAArrivalAndDepartureSectionBuilder ()
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@end

@implementation OBAArrivalAndDepartureSectionBuilder

- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO {
    self = [super init];

    if (self) {
        _modelDAO = modelDAO;
    }

    return self;
}

- (OBADepartureRow*)createDepartureRowForStop:(OBAArrivalAndDepartureV2*)dep {
    OBAGuard(dep) else {
        return nil;
    }

    OBADepartureRow *row = [[OBADepartureRow alloc] initWithAction:nil];
    row.routeName = dep.bestAvailableName;
    row.destination = dep.tripHeadsign.capitalizedString;
    row.statusText = [OBADepartureCellHelpers statusTextForArrivalAndDeparture:dep];
    row.model = dep;
    row.bookmarkExists = [self hasBookmarkForArrivalAndDeparture:dep];
    row.alarmExists = [self hasAlarmForArrivalAndDeparture:dep];
    row.hasArrived = dep.minutesUntilBestDeparture > 0;

    OBAUpcomingDeparture *upcoming = [[OBAUpcomingDeparture alloc] initWithDepartureDate:dep.bestArrivalDepartureDate departureStatus:dep.departureStatus arrivalDepartureState:dep.arrivalDepartureState];
    row.upcomingDepartures = @[upcoming];

    return row;
}

- (BOOL)hasBookmarkForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    return !![self.modelDAO bookmarkForArrivalAndDeparture:arrivalAndDeparture];
}

- (BOOL)hasAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    id val = [self.modelDAO alarmForKey:dep.alarmKey];
    return !!val;
}

@end
