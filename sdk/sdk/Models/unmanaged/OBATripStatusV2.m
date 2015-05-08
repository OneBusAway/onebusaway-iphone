#import "OBATripStatusV2.h"


@implementation OBATripStatusV2

- (OBATripV2*) activeTrip {
    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.activeTripId];
}

- (OBATripInstanceRef*) tripInstance {
    return [OBATripInstanceRef tripInstance:self.activeTripId serviceDate:self.serviceDate vehicleId:self.vehicleId];
}

@end
