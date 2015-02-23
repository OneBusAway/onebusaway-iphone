#import "OBATripScheduleV2.h"


@implementation OBATripScheduleV2

- (OBATripV2*) previousTrip {
    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.previousTripId];
}

- (OBATripV2*) nextTrip {
    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.nextTripId];
}


@end
