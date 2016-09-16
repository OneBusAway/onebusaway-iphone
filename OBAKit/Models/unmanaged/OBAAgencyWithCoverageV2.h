#import <MapKit/MapKit.h>

#import "OBAHasReferencesV2.h"
#import "OBAAgencyV2.h"
#import "OBARegionBoundsV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAAgencyWithCoverageV2 : OBAHasReferencesV2
@property(nonatomic,copy) NSString *agencyId;
@property(weak,nonatomic,readonly) OBAAgencyV2 *agency;
@property(nonatomic,assign) CLLocationCoordinate2D coordinate;

@property(nonatomic,assign) double lat;
@property(nonatomic,assign) double latSpan;
@property(nonatomic,assign) double lon;
@property(nonatomic,assign) double lonSpan;

@property(nonatomic,copy,nullable,readonly) OBARegionBoundsV2 *regionBounds;

- (NSComparisonResult)compareUsingAgencyName:(OBAAgencyWithCoverageV2*)obj;

@end

NS_ASSUME_NONNULL_END
