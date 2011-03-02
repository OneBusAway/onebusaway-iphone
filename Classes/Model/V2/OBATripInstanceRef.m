#import "OBATripInstanceRef.h"


@implementation OBATripInstanceRef

@synthesize tripId = _tripId;
@synthesize serviceDate = _serviceDate;
@synthesize vehicleId = _vehicleId;

- (id) initWithTripId:(NSString*)tripId serviceDate:(long long)serviceDate vehicleId:(NSString*)vehicleId {
	if( self = [super init] ) {
		_tripId = tripId;
		_serviceDate = serviceDate;
		_vehicleId = vehicleId;
	}
	return self;
}

+ (OBATripInstanceRef*) tripInstance:(NSString*)tripId serviceDate:(long long)serviceDate vehicleId:(NSString*)vehicleId {
	return [[[OBATripInstanceRef alloc] initWithTripId:tripId serviceDate:serviceDate vehicleId:vehicleId] autorelease];
}

- (OBATripInstanceRef*) copyWithNewTripId:(NSString*)newTripId {
	return [OBATripInstanceRef tripInstance:newTripId serviceDate:self.serviceDate vehicleId:self.vehicleId];
}

@end
