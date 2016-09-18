#import <OBAKit/OBATripScheduleV2.h>

@implementation OBATripScheduleV2

- (OBATripV2*)previousTrip {
    if (!self.previousTripId) {
        return nil;
    }

    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.previousTripId];
}

- (OBATripV2*)nextTrip {
    if (!self.nextTripId) {
        return nil;
    }

    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.nextTripId];
}


@end
