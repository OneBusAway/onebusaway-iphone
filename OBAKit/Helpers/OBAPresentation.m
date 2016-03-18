#import "OBAPresentation.h"

@implementation OBAPresentation

+ (NSString*) getTripHeadsignForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    NSString * name = arrivalAndDeparture.tripHeadsign;
    if( name )
        return name;
    return [self getTripHeadsignForTrip:arrivalAndDeparture.trip];
}

+ (NSString*) getTripHeadsignForTrip:(OBATripV2*)trip {
    if (trip.tripHeadsign) {
        return trip.tripHeadsign;
    }
    else if (trip.route.longName) {
        return trip.route.longName;
    }
    else {
        return NSLocalizedString(@"Headed somewhere...", @"SHRUG");
    }
}
@end