#import "OBAHasReferencesV2.h"


@interface OBAStopV2 :  OBAHasReferencesV2 <MKAnnotation>
{
}


@property (nonatomic, strong) NSString * stopId;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * code;
@property (nonatomic, strong) NSString * direction;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSArray * routeIds;

@property (weak, nonatomic,readonly) NSArray * routes;

@property (nonatomic,readonly) double lat;
@property (nonatomic,readonly) double lon;
@property (nonatomic,readonly) CLLocationCoordinate2D coordinate;

- (NSComparisonResult) compareUsingName:(OBAStopV2*)aStop;

- (NSString*) routeNamesAsString;

@end