@import MapKit;

#import "OBAHasReferencesV2.h"
#import "OBAAgencyV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAAgencyWithCoverageV2 : OBAHasReferencesV2
@property(nonatomic,copy) NSString *agencyId;
@property(weak,nonatomic,readonly) OBAAgencyV2 *agency;
@property(nonatomic,assign) CLLocationCoordinate2D coordinate;

- (NSComparisonResult)compareUsingAgencyName:(OBAAgencyWithCoverageV2*)obj;

@end

NS_ASSUME_NONNULL_END