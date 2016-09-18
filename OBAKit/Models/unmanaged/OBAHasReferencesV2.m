#import <OBAKit/OBAHasReferencesV2.h>

@implementation OBAHasReferencesV2

- (instancetype)init {
    return [self initWithReferences:[[OBAReferencesV2 alloc] init]];
}

- (instancetype)initWithReferences:(OBAReferencesV2*)refs {
    self = [super init];
    if (self) {
        _references = refs;
    }
    return self;
}

@end
