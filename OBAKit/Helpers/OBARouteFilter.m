//
//  OBARouteFilter.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/23/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBARouteFilter.h"

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

@end
