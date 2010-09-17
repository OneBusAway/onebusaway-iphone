#import "OBAAgencyV2.h"


@implementation OBAAgencyV2 

@synthesize agencyId;
@synthesize url;
@synthesize name;

- (void) dealloc {
	self.agencyId = nil;
	self.url = nil;
	self.name = nil;
	[super dealloc];
}

@end
