#import "OBAHasReferencesV2.h"
#import "OBAAgencyV2.h"


@interface OBARouteV2 :  OBAHasReferencesV2 {

}

@property (nonatomic, strong) NSString * routeId;
@property (nonatomic, strong) NSString * shortName;
@property (nonatomic, strong) NSString * longName;
@property (nonatomic, strong) NSNumber * routeType;

@property (nonatomic, strong) NSString * agencyId;
@property (weak, nonatomic, readonly) OBAAgencyV2 * agency;

@property (weak, nonatomic, readonly) NSString * safeShortName;

- (NSComparisonResult) compareUsingName:(OBARouteV2*)aRoute;

@end