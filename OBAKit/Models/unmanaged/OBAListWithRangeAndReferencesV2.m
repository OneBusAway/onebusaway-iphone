#import "OBAListWithRangeAndReferencesV2.h"


@implementation OBAListWithRangeAndReferencesV2

- (id) initWithReferences:(OBAReferencesV2*)refs {
    self = [super initWithReferences:refs];
    if (self) {
        _values = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void) addValue:(id)value {
    [_values addObject:value];
}

- (NSUInteger) count {
    return _values.count;
}
@end
