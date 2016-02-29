#import "OBAReferencesV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAHasReferencesV2 : NSObject {
    OBAReferencesV2 * _references;
}

- (id) initWithReferences:(OBAReferencesV2*)refs;

@property (nonatomic,strong) OBAReferencesV2 * references;

@end

NS_ASSUME_NONNULL_END