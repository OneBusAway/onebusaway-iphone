#import "OBAVehicleStatusV2.h"


@implementation OBAVehicleStatusV2

- (OBATripV2*) trip {
    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.tripId];
}

@end
