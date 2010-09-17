#import "OBAHasReferencesV2.h"


@implementation OBAHasReferencesV2

@synthesize references = _references;

- (void) dealloc {
	[_references release];
	[super dealloc];
}

@end
