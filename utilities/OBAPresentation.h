#import <Foundation/Foundation.h>
#import "OBAArrivalAndDepartureV2.h"

@interface OBAPresentation : NSObject

+ (NSString*) getRouteShortNameForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;

+ (NSString*) getTripHeadsignForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;

+ (NSString*) getTripHeadsignForTrip:(OBATripV2*)trip;
@end
