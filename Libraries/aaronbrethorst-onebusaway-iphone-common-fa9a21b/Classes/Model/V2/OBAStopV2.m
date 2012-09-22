#import "OBAStopV2.h"
#import "OBARouteV2.h"


@implementation OBAStopV2

- (NSArray*) routes {

	NSMutableArray * sRoutes = [NSMutableArray array];
	
	OBAReferencesV2 * refs = self.references;
    
	for ( NSString * routeId in self.routeIds ) {
		OBARouteV2 * route = [refs getRouteForId:routeId];
		if (route) {
			[sRoutes addObject:route];
        }
	}
	
	[sRoutes sortUsingSelector:@selector(compareUsingName:)];
	
	return sRoutes;
}	
	

- (double) lat {
	return [self.latitude doubleValue];
}

- (double) lon {
	return [self.longitude doubleValue];
}

- (NSComparisonResult) compareUsingName:(OBAStopV2*)aStop {
	return [self.name compare:aStop.name options:NSNumericSearch];
}

- (NSString*) routeNamesAsString {
    NSMutableArray *safeShortNames = [NSMutableArray array];
    
    for (OBARouteV2 *route in self.routes) {
        [safeShortNames addObject:route.safeShortName];
    }
    
    return [safeShortNames componentsJoinedByString:@", "];
}

#pragma mark - MKAnnotation

- (NSString*) title {
	return self.name;
}

- (NSString*) subtitle {
	NSString * r = [self routeNamesAsString];

	if (self.direction) {
        return [NSString stringWithFormat:NSLocalizedString(@"%@ bound - Routes: %@", @""), self.direction, r];
    }
    else {
        return [NSString stringWithFormat:NSLocalizedString(@"Routes: %@", @""), r];
    }
}

- (CLLocationCoordinate2D) coordinate {
	CLLocationCoordinate2D c = {self.lat,self.lon};
	return c;
}

#pragma mark NSObject

- (BOOL) isEqual:(id)object {
	if (![object isKindOfClass:[OBAStopV2 class]])
		return NO;
	OBAStopV2 * stop = object;
	return [self.stopId isEqual:stop.stopId];
}

- (NSString*) description {
	return [NSString stringWithFormat:@"Stop: id=%@",self.stopId];
}

@end
