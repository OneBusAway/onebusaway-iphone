#import "OBAArrivalAndDepartureInstanceRef.h"


@implementation OBAArrivalAndDepartureInstanceRef

- (id) initWithTripInstance:(OBATripInstanceRef*)tripInstance stopId:(NSString*)stopId stopSequence:(NSInteger)stopSequence {
    self = [super init];
    if( self ) {
        _tripInstance = tripInstance;
        _stopId = stopId;
        _stopSequence = stopSequence;
    }
    return self;
}


+ (OBAArrivalAndDepartureInstanceRef*) refWithTripInstance:(OBATripInstanceRef*)tripInstance stopId:(NSString*)stopId stopSequence:(NSInteger)stopSequence {
    return [[self alloc] initWithTripInstance:tripInstance stopId:stopId stopSequence:stopSequence];
}

- (BOOL) isEqualWithOptionalVehicleId:(OBAArrivalAndDepartureInstanceRef*)ref {
    if ( ![_tripInstance isEqualWithOptionalVehicleId:ref.tripInstance] )
        return NO;
    if ( ![_stopId isEqualToString:ref.stopId] )
        return NO;
    if ( _stopSequence != ref.stopSequence )
        return NO;
    return YES;
}

- (BOOL) isEqual:(id)object {
    if (self == object)
        return YES;
    if (object == nil)
        return NO;
    if ( ![object isKindOfClass:[OBAArrivalAndDepartureInstanceRef class]] )
        return NO;
    OBAArrivalAndDepartureInstanceRef * instanceRef = object;
    if ( ![_tripInstance isEqual:instanceRef.tripInstance] )
        return NO;
    if ( ![_stopId isEqualToString:instanceRef.stopId] )
        return NO;
    if ( _stopSequence != instanceRef.stopSequence )
        return NO;
    return YES;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"(tripInstance=%@, stopId=%@, stopSequence=%d)",[_tripInstance description],_stopId,_stopSequence];
}

@end
