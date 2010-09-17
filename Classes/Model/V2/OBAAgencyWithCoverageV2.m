#import "OBAAgencyWithCoverageV2.h"


@implementation OBAAgencyWithCoverageV2

@synthesize agencyId = _agencyId;
@synthesize coordinate = _coordinate;

- (void) dealloc {
	[_agencyId release];
	[super dealloc];
}

- (OBAAgencyV2*) agency {
	OBAReferencesV2 * refs = [self references];
	return [refs getAgencyForId:_agencyId];
}

@end
