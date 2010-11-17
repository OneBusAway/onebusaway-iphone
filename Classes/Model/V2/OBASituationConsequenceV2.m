#import "OBASituationConsequenceV2.h"


@implementation OBASituationConsequenceV2

@synthesize condition;
@synthesize diversionPath;

- (void) dealloc {
	[self.condition release];
	[self.diversionPath release];
	[super dealloc];
}

@end
