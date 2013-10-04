#import "OBAArrivalAndDepartureV2.h"


@implementation OBAArrivalAndDepartureV2

@synthesize situationIds = _situationIds;

- (id) init {
    self = [super init];
    if (self) {
        _situationIds = [[NSMutableArray alloc] init];
    }
    return self;
}


- (OBARouteV2*) route {
    OBAReferencesV2 * refs = [self references];
    return [refs getRouteForId:self.routeId];
}

- (OBAStopV2*) stop {
    OBAReferencesV2 * refs = [self references];
    return [refs getStopForId:self.stopId];
}

- (OBATripV2*) trip {
    OBAReferencesV2 * refs = [self references];
    return [refs getTripForId:self.tripId];

}

- (OBAArrivalAndDepartureInstanceRef *) instance {
    return [OBAArrivalAndDepartureInstanceRef refWithTripInstance:self.tripInstance stopId:self.stopId stopSequence:self.stopSequence];
}

- (OBATripInstanceRef *) tripInstance {
    return [OBATripInstanceRef tripInstance:self.tripId serviceDate:self.serviceDate vehicleId:self.tripStatus.vehicleId];
}

- (long long) bestArrivalTime {
    return self.predictedArrivalTime == 0 ? self.scheduledArrivalTime : self.predictedArrivalTime;
}

- (long long) bestDepartureTime {
    return self.predictedDepartureTime == 0 ? self.scheduledDepartureTime : self.predictedDepartureTime;
}

- (NSArray*) situations {
    
    NSMutableArray * rSituations = [NSMutableArray array];
    
    OBAReferencesV2 * refs = self.references;
    
    for( NSString * situationId in self.situationIds ) {
        OBASituationV2 * situation = [refs getSituationForId:situationId];
        if( situation )
            [rSituations addObject:situation];
    }
    
    return rSituations;
}

- (void) addSituationId:(NSString*)situationId {
    [_situationIds addObject:situationId];
}

@end
