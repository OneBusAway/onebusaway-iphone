#import <OBAKit/OBATripInstanceRef.h>

@implementation OBATripInstanceRef

- (id) initWithTripId:(NSString*)tripId serviceDate:(long long)serviceDate vehicleId:(NSString*)vehicleId {
    self = [super init];
    if( self ) {
        _tripId = tripId;
        _serviceDate = serviceDate;
        _vehicleId = vehicleId;
    }
    return self;
}


+ (OBATripInstanceRef*) tripInstance:(NSString*)tripId serviceDate:(long long)serviceDate vehicleId:(NSString*)vehicleId {
    return [[OBATripInstanceRef alloc] initWithTripId:tripId serviceDate:serviceDate vehicleId:vehicleId];
}

- (OBATripInstanceRef*)copyWithNewTripId:(NSString*)newTripId {
    return [OBATripInstanceRef tripInstance:newTripId serviceDate:self.serviceDate vehicleId:self.vehicleId];
}

- (BOOL) isEqual:(id)object {
    if (self == object)
        return YES;
    if (object == nil)
        return NO;
    if ( ![object isKindOfClass:[OBATripInstanceRef class]] )
        return NO;
    OBATripInstanceRef * instanceRef = object;
    if ( ![_tripId isEqualToString:instanceRef.tripId] )
        return NO;
    if ( _serviceDate != instanceRef.serviceDate )
        return NO;
    if ( ! [_vehicleId isEqualToString:_vehicleId] )
        return NO;
    return YES;
}

- (NSString*) description {
    return [NSString stringWithFormat:@"(tripId=%@ serviceDate=%lld vehicleId=%@)",_tripId,_serviceDate,_vehicleId];
}

@end
