#import "OBAHasReferencesV2.h"
#import "OBAAgencyV2.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, OBARouteType) {
    OBARouteTypeLightRail = 0,
    OBARouteTypeMetro = 1,
    OBARouteTypeTrain = 2,
    OBARouteTypeBus = 3,
    OBARouteTypeFerry = 4,
    OBARouteTypeUnknown = 999
};

@interface OBARouteV2 : OBAHasReferencesV2

@property (nonatomic, strong) NSString * routeId;
@property (nonatomic, strong) NSString * shortName;
@property (nonatomic, strong) NSString * longName;
@property (nonatomic, strong) NSNumber * routeType;

@property (nonatomic, strong) NSString * agencyId;
@property (weak, nonatomic, readonly) OBAAgencyV2 * agency;

@property (weak, nonatomic, readonly) NSString * safeShortName;

- (NSComparisonResult) compareUsingName:(OBARouteV2*)aRoute;

@end

NS_ASSUME_NONNULL_END