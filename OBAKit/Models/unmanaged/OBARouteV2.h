#import "OBAHasReferencesV2.h"
#import "OBAAgencyV2.h"
#import "OBARouteType.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBARouteV2 : OBAHasReferencesV2<NSCopying,NSCoding>
@property(nonatomic,strong) NSString * routeId;
@property(nonatomic,strong) NSString * shortName;
@property(nonatomic,strong) NSString * longName;
@property(nonatomic,strong) NSNumber * routeType;

@property(nonatomic,strong) NSString * agencyId;
@property(nonatomic,copy, readonly) OBAAgencyV2 *agency;
@property(nonatomic,copy, readonly) NSString * safeShortName;

- (NSComparisonResult) compareUsingName:(OBARouteV2*)aRoute;

@end

NS_ASSUME_NONNULL_END