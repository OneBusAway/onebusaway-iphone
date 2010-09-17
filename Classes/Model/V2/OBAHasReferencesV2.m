#import "OBAHasReferencesV2.h"


@implementation OBAHasReferencesV2

@synthesize references = _references;

- (id) initWithReferences:(OBAReferencesV2*)refs {
	if( self = [super init]) {
		self.references = refs;
	}
	return self;
}

- (void) dealloc {
	[_references release];
	[super dealloc];
}

@end
