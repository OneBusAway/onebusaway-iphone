#import <Foundation/Foundation.h>
#import "OBAArrivalAndDepartureV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAPresentation : NSObject

+ (NSString*) getTripHeadsignForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;

+ (NSString*) getTripHeadsignForTrip:(OBATripV2*)trip;
@end

NS_ASSUME_NONNULL_END