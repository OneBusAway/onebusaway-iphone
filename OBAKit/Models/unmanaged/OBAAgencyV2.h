#import <OBAKit/OBAHasReferencesV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAAgencyV2 : OBAHasReferencesV2<NSCopying,NSCoding>

@property (nonatomic, strong) NSString *agencyId;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *name;

@end

NS_ASSUME_NONNULL_END
