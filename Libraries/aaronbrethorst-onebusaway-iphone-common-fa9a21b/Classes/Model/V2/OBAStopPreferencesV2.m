#import "OBAStopPreferencesV2.h"


@implementation OBAStopPreferencesV2

@synthesize sortTripsByType = _sortTripsByType;
@synthesize routeFilter = _routeFilter;
- (id) init {
    self = [super init];
	if( self ) {
		_sortTripsByType = OBASortTripsByDepartureTimeV2;
		_routeFilter = [[NSMutableSet alloc] init];
	}
	return self;
}

- (id) initWithStopPreferences:(OBAStopPreferencesV2*)preferences {
    self = [super init];
	if( self ) {
		_sortTripsByType = preferences.sortTripsByType;
		_routeFilter = [[NSMutableSet alloc] initWithSet:[preferences routeFilter]];
	}
	return self;	
}

- (id) initWithCoder:(NSCoder*)coder {
    self = [super init];
	if( self ) {
		NSNumber * sortTripsByType = [coder decodeObjectForKey:@"sortTripsByType"];
		_sortTripsByType = [sortTripsByType intValue];
		_routeFilter =  [coder decodeObjectForKey:@"routeFilter"];
	}
	return self;
}
	

- (BOOL) isRouteIdEnabled:(NSString*) routeId {
	return ! [_routeFilter containsObject:routeId];
}
		
- (void) setEnabled:(BOOL)isEnabled forRouteId:(NSString*)routeId {
	if( isEnabled )
		[_routeFilter removeObject:routeId];
	else
		[_routeFilter addObject:routeId];
}

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
	[coder encodeObject:[NSNumber numberWithInt:_sortTripsByType] forKey:@"sortTripsByType"];
	[coder encodeObject:_routeFilter forKey:@"routeFilter"];
}
	

@end
