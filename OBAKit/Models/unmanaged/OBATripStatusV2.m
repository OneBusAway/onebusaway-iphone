#import <OBAKit/OBATripStatusV2.h>
#import <OBAKit/NSObject+OBADescription.h>

@implementation OBATripStatusV2

- (OBATripV2*) activeTrip {
    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.activeTripId];
}

- (OBATripInstanceRef*) tripInstance {
    return [OBATripInstanceRef tripInstance:self.activeTripId serviceDate:self.serviceDate vehicleId:self.vehicleId];
}

- (NSString*)description {
    return [self oba_description:@[@"activeTripId", @"activeTrip", @"serviceDate", @"frequency", @"location", @"predicted", @"scheduleDeviation", @"vehicleId", @"lastUpdateTime", @"lastKnownLocation", @"tripInstance"]];
}
@end
