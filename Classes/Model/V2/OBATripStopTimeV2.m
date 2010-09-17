#import "OBATripStopTimeV2.h"


@implementation OBATripStopTimeV2

@synthesize arrivalTime;
@synthesize departureTime;
@synthesize stopId;

- (OBAStopV2*) stop {
	OBAReferencesV2 * refs = self.references;
	return [refs getStopForId:self.stopId];
}

@end
