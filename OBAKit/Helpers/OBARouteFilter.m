//
//  OBARouteFilter.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/23/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBARouteFilter.h>
#import <OBAKit/OBAArrivalAndDepartureV2.h>

@implementation OBARouteFilter

- (instancetype)initWithStopPreferences:(OBAStopPreferencesV2*)stopPreferences {
    self = [super init];

    if (self) {
        _stopPreferences = stopPreferences;
        _showFilteredRoutes = NO;
    }
    return self;
}

- (BOOL)shouldShowRouteID:(NSString*)routeID {
    if (self.showFilteredRoutes) {
        return YES;
    }
    else {
        return ![self.stopPreferences isRouteIDDisabled:routeID];
    }
}

- (BOOL)hasFilteredRoutes {
    return self.stopPreferences.hasFilteredRoutes;
}

- (NSArray<OBAArrivalAndDepartureV2*>*)filteredArrivalsAndDepartures:(NSArray<OBAArrivalAndDepartureV2*>*)arrivalsAndDepartures {
    NSMutableArray *filtered = [[NSMutableArray alloc] init];

    for (OBAArrivalAndDepartureV2 *dep in arrivalsAndDepartures) {
        if ([self shouldShowRouteID:dep.routeId]) {
            [filtered addObject:dep];
        }
    }

    return [NSArray arrayWithArray:filtered];
}

@end
