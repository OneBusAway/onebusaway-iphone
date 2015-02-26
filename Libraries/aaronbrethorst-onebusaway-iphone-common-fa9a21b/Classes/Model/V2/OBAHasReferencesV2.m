#import "OBAHasReferencesV2.h"


@implementation OBAHasReferencesV2

- (id) initWithReferences:(OBAReferencesV2*)refs {
    self = [super init];
    if( self ) {
        _references = refs;
    }
    return self;
}


@end
