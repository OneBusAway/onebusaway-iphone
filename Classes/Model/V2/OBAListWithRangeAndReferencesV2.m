#import "OBAListWithRangeAndReferencesV2.h"


@implementation OBAListWithRangeAndReferencesV2

@synthesize limitExceeded = _limitExceeded;
@synthesize outOfRange = _outOfRange;
@synthesize values = _values;

- (id) init {
	if (self = [super init]) {
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
