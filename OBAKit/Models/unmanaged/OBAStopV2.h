#import "OBAHasReferencesV2.h"
@import MapKit;
#import "OBARouteType.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAStopV2 : OBAHasReferencesV2 <MKAnnotation,NSCoding,NSCopying>

@property (nonatomic, strong) NSString * stopId;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * code;
@property (nonatomic, strong) NSString * direction;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSArray<NSString*> *routeIds;

@property(nonatomic,strong,readonly) NSArray<OBARouteV2*> *routes;

@property (nonatomic,readonly) double lat;
@property (nonatomic,readonly) double lon;
@property (nonatomic,readonly) CLLocationCoordinate2D coordinate;

- (NSComparisonResult)compareUsingName:(OBAStopV2*)aStop;

- (NSString*)routeNamesAsString;

- (OBARouteType)firstAvailableRouteTypeForStop;

@end

NS_ASSUME_NONNULL_END