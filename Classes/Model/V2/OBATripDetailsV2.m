#import "OBATripDetailsV2.h"


@implementation OBATripDetailsV2

@synthesize tripId;
@synthesize schedule;

- (OBATripV2*) trip {
	OBAReferencesV2 * refs = self.references;
	return [refs getTripForId:self.tripId];
}

@end
