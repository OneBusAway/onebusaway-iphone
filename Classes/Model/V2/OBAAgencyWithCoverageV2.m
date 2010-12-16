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

- (NSComparisonResult) compareUsingAgencyName:(OBAAgencyWithCoverageV2*)obj {
	NSString * nameA = [self.agency name];
	NSString * nameB = [obj.agency name];
	return [nameA compare:nameB options:NSNumericSearch];
}

@end
