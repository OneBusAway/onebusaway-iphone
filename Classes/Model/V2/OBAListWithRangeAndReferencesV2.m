#import "OBAListWithRangeAndReferencesV2.h"


@implementation OBAListWithRangeAndReferencesV2

@synthesize limitExceeded = _limitExceeded;
@synthesize outOfRange = _outOfRange;
@synthesize values = _values;

- (id) initWithReferences:(OBAReferencesV2*)refs {
	if (self = [super initWithReferences:refs]) {
		_values = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_values release];
	[super dealloc];
}

- (void) addValue:(id)value {
	[_values addObject:value];
}

- (NSUInteger) count {
	return [_values count];
}

@end
