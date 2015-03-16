#import "OBATripStopTimeV2.h"


@implementation OBATripStopTimeV2

- (OBAStopV2*) stop {
    OBAReferencesV2 * refs = self.references;
    return [refs getStopForId:self.stopId];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"<%@: %p> :: {arrivalTime: %@, departureTime: %@, stopId: %@, stop: %@}", self.class, self, @(self.arrivalTime), @(self.departureTime), self.stopId, self.stop];
}
@end
