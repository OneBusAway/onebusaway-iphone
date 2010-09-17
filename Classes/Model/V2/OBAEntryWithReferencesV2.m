#import "OBAEntryWithReferencesV2.h"


@implementation OBAEntryWithReferencesV2

@synthesize entry = _entry;

- (void) dealloc {
	[_entry release];
	[super dealloc];
}
@end
