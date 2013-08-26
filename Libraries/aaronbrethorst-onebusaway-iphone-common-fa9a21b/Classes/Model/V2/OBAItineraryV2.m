#import "OBAItineraryV2.h"


@implementation OBAItineraryV2

@synthesize legs = _legs;

- (id) init {
    self = [super init];
    if (self) { 
        _legs = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void) addLeg:(OBALegV2*)leg {
    [_legs addObject:leg];
}

- (OBALegV2*) firstTransitLeg {
    for( OBALegV2 * leg in _legs ) {
        if( leg.transitLeg )
            return leg;
    }
    return nil;
}

@end
