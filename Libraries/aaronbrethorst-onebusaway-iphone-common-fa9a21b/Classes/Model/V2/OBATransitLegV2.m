#import "OBATransitLegV2.h"


@implementation OBATransitLegV2

@synthesize tripId;
@synthesize serviceDate;
@synthesize vehicleId;
@synthesize frequency;
@synthesize fromStopId;
@synthesize fromStopSequence;
@synthesize toStopId;
@synthesize toStopSequence;
@synthesize tripHeadsign;
@synthesize routeShortName;
@synthesize routeLongName;
@synthesize path;
@synthesize scheduledDepartureTime;
@synthesize predictedDepartureTime;
@synthesize scheduledArrivalTime;
@synthesize predictedArrivalTime;


- (OBATripV2*) trip {
    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.tripId];
}

- (OBAStopV2*) fromStop {
    OBAReferencesV2 * refs = self.references;
    return [refs getStopForId:self.fromStopId];
}

- (OBAStopV2*) toStop {
    OBAReferencesV2 * refs = self.references;
    return [refs getStopForId:self.toStopId];
}

- (long long) bestDepartureTime {
    if( self.predictedDepartureTime > 0 )
        return self.predictedDepartureTime;
    return self.scheduledDepartureTime;
}

- (long long) bestArrivalTime {
    if( self.predictedArrivalTime > 0 )
        return self.predictedArrivalTime;
    return self.scheduledArrivalTime;
}

- (OBATripInstanceRef*) tripInstanceRef {
    return [OBATripInstanceRef tripInstance:self.tripId serviceDate:self.serviceDate vehicleId:self.vehicleId];
}

- (OBAArrivalAndDepartureInstanceRef*) departureInstanceRef {
    return [OBAArrivalAndDepartureInstanceRef refWithTripInstance:self.tripInstanceRef stopId:self.fromStopId stopSequence:self.fromStopSequence];
}

- (OBAArrivalAndDepartureInstanceRef*) arrivalInstanceRef {
    return [OBAArrivalAndDepartureInstanceRef refWithTripInstance:self.tripInstanceRef stopId:self.toStopId stopSequence:self.toStopSequence];
    
}


@end
