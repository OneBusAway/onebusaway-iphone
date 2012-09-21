#import "OBAVehicleStatusV2.h"


@implementation OBAVehicleStatusV2

@synthesize vehicleId;
@synthesize lastUpdateTime;
@synthesize tripId;
@synthesize tripStatus;

- (void) dealloc {
	self.tripId = tripId;
	self.tripStatus = tripStatus;
}

- (OBATripV2*) trip {
	OBAReferencesV2 * refs = self.references;
	return [refs getTripForId:self.tripId];
}

@end
