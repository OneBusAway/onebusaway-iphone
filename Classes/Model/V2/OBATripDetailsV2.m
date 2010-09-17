#import "OBATripDetailsV2.h"


@implementation OBATripDetailsV2

@synthesize tripId;
@synthesize schedule;
@synthesize status;

- (OBATripV2*) trip {
	OBAReferencesV2 * refs = self.references;
	return [refs getTripForId:self.tripId];
}

@end
