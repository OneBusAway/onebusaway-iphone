@import MapKit;

#import "OBAHasReferencesV2.h"
#import "OBAAgencyV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAAgencyWithCoverageV2 : OBAHasReferencesV2

@property (nonatomic,strong) NSString *agencyId;
@property (weak, nonatomic,readonly) OBAAgencyV2 *agency;
@property (nonatomic) CLLocationCoordinate2D coordinate;

- (NSComparisonResult) compareUsingAgencyName:(OBAAgencyWithCoverageV2*)obj;

@end

NS_ASSUME_NONNULL_END