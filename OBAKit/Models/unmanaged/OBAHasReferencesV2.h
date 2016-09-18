#import <OBAKit/OBAReferencesV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAHasReferencesV2 : NSObject
@property(nonatomic,strong) OBAReferencesV2 *references;

- (instancetype)initWithReferences:(OBAReferencesV2*)refs;

@end

NS_ASSUME_NONNULL_END
