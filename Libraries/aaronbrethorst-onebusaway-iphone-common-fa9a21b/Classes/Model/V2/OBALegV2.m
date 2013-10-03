#import "OBALegV2.h"


@implementation OBALegV2

@synthesize streetLegs = _streetLegs;

- (id) init {
    self = [super init];
    if (self) {
        _streetLegs = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void) addStreetLeg:(OBAStreetLegV2 *)streetLeg {
    [_streetLegs addObject:streetLeg];
}

@end
