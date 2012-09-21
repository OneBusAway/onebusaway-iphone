#import "OBATripStatusV2.h"


@implementation OBATripStatusV2

@synthesize activeTripId;
@synthesize serviceDate;
@synthesize frequency;
@synthesize location;
@synthesize predicted;
@synthesize scheduleDeviation;
@synthesize vehicleId;

@synthesize lastUpdateTime;
@synthesize lastKnownLocation;


- (OBATripV2*) activeTrip {
	OBAReferencesV2 * refs = self.references;
	return [refs getTripForId:self.activeTripId];
}

- (OBATripInstanceRef*) tripInstance {
	return [OBATripInstanceRef tripInstance:self.activeTripId serviceDate:self.serviceDate vehicleId:self.vehicleId];
}

@end
