#import "OBAHasReferencesV2.h"
#import "OBARouteV2.h"


@interface OBATripV2 : OBAHasReferencesV2 {

}

@property (nonatomic, retain) NSString * tripId;
@property (nonatomic, retain) NSString * routeId;
@property (nonatomic, retain) NSString * routeShortName;
@property (nonatomic, retain) NSString * tripShortName;
@property (nonatomic, retain) NSString * tripHeadsign;
@property (nonatomic, retain) NSString * serviceId;
@property (nonatomic, retain) NSString * shapeId;
@property (nonatomic, retain) NSString * directionId;

@property (nonatomic, readonly) OBARouteV2 * route;

@property (nonatomic, readonly) NSString * asLabel;

@end
