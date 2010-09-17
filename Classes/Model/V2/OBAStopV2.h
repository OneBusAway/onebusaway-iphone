#import "OBAHasReferencesV2.h"


@interface OBAStopV2 :  OBAHasReferencesV2 <MKAnnotation>
{
}


@property (nonatomic, retain) NSString * stopId;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * code;
@property (nonatomic, retain) NSString * direction;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSArray * routeIds;

@property (nonatomic,readonly) NSArray * routes;

@property (nonatomic,readonly) double lat;
@property (nonatomic,readonly) double lon;
@property (nonatomic,readonly) CLLocationCoordinate2D coordinate;

- (NSComparisonResult) compareUsingName:(OBAStopV2*)aStop;

- (NSString*) routeNamesAsString;

@end