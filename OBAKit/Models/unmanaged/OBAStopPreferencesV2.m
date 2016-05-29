#import "OBAStopPreferencesV2.h"
#import "NSObject+OBADescription.h"

NSString * _Nullable NSStringFromOBASortTripsByTypeV2(OBASortTripsByTypeV2 val);
NSString * _Nullable NSStringFromOBASortTripsByTypeV2(OBASortTripsByTypeV2 val) {
    switch (val) {
        case OBASortTripsByDepartureTimeV2:
            return @"OBASortTripsByDepartureTimeV2";
        case OBASortTripsByRouteNameV2:
            return @"OBASortTripsByRouteNameV2";
        default:
            return nil;
    }
}

@implementation OBAStopPreferencesV2
@dynamic hasFilteredRoutes;

- (instancetype)init {
    self = [super init];
    if (self) {
        _sortTripsByType = OBASortTripsByDepartureTimeV2;
        _routeFilter = [[NSMutableSet alloc] init];
    }
    return self;
}

- (instancetype)initWithStopPreferences:(OBAStopPreferencesV2*)preferences {
    self = [super init];
    if( self ) {
        _sortTripsByType = preferences.sortTripsByType;
        _routeFilter = [[NSMutableSet alloc] initWithSet:preferences.routeFilter];
    }
    return self;    
}

#pragma mark - NSCoder

- (instancetype)initWithCoder:(NSCoder*)coder {
    self = [super init];
    if( self ) {
        NSNumber * sortTripsByType = [coder decodeObjectForKey:@"sortTripsByType"];
        _sortTripsByType = [sortTripsByType unsignedIntegerValue];
        _routeFilter = [coder decodeObjectForKey:@"routeFilter"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {
    [coder encodeObject:[NSNumber numberWithInt:_sortTripsByType] forKey:@"sortTripsByType"];
    [coder encodeObject:_routeFilter forKey:@"routeFilter"];
}


#pragma mark - Public Methods

- (BOOL)isRouteIDDisabled:(NSString*)routeID {
    return [_routeFilter containsObject:routeID];
}

- (BOOL)isRouteIdEnabled:(NSString*)routeId {
    return ![_routeFilter containsObject:routeId];
}
        
- (void)setEnabled:(BOOL)isEnabled forRouteId:(NSString*)routeId {
    if (isEnabled) {
        [_routeFilter removeObject:routeId];
    }
    else {
        [_routeFilter addObject:routeId];
    }
}

- (BOOL)toggleRouteID:(NSString*)routeID {
    if ([_routeFilter containsObject:routeID]) {
        [_routeFilter removeObject:routeID];
    }
    else {
        [_routeFilter addObject:routeID];
    }

    return ![_routeFilter containsObject:routeID];
}

- (BOOL)hasFilteredRoutes {
    return self.routeFilter.count > 0;
}

- (NSString*)formattedSortTripsByType {
    return NSStringFromOBASortTripsByTypeV2(self.sortTripsByType);
}

#pragma mark - NSObject

- (NSString*)description {
    return [self oba_description:@[@"formattedSortTripsByType", @"routeFilter", @"hasFilteredRoutes"]];
}

@end
