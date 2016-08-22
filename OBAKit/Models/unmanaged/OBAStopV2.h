#import "OBAHasReferencesV2.h"
@import MapKit;
#import "OBARouteType.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAStopV2 : OBAHasReferencesV2 <MKAnnotation,NSCoding,NSCopying>

@property(nonatomic,copy,readonly) NSString *nameWithDirection;

@property (nonatomic, strong) NSString * stopId;
@property (nonatomic, strong) NSString * name;

/**
 The stop number. A unique identifier for the stop
 within its transit system. In Puget Sound, e.g.,
 these stop numbers are actually written on the bus stops.
 */
@property (nonatomic, strong) NSString * code;
@property (nonatomic, strong) NSString * direction;
@property (nonatomic, strong) NSArray<NSString*> *routeIds;

@property(nonatomic,strong,readonly) NSArray<OBARouteV2*> *routes;

@property(nonatomic,assign) double lat;
@property(nonatomic,assign) double lon;
@property(nonatomic,readonly) CLLocationCoordinate2D coordinate;

- (NSComparisonResult)compareUsingName:(OBAStopV2*)aStop;

- (NSString*)routeNamesAsString;

- (OBARouteType)firstAvailableRouteTypeForStop;

@end

NS_ASSUME_NONNULL_END