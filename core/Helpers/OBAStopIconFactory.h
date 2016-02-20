#import "OBAStopV2.h"
#import "OBARouteV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAStopIconFactory : NSObject

+ (UIImage*) getIconForStop:(OBAStopV2*)stop;
+ (UIImage*) getIconForStop:(OBAStopV2*)stop includeDirection:(BOOL)includeDirection;

+ (UIImage*) getModeIconForRoute:(OBARouteV2*)route;
+ (UIImage*) getModeIconForRoute:(OBARouteV2*)route selected:(BOOL)selected;
+ (UIImage*) getModeIconForRouteIconType:(NSString*)routeType selected:(BOOL)selected;

+ (NSString*) getRouteIconTypeForRoutes:(NSArray*)routes;

@end

NS_ASSUME_NONNULL_END