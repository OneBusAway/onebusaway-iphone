#import "OBAReferencesV2.h"


@interface OBAHasReferencesV2 : NSObject {
    OBAReferencesV2 * _references;
}

- (id) initWithReferences:(OBAReferencesV2*)refs;

@property (nonatomic,strong) OBAReferencesV2 * references;

@end
