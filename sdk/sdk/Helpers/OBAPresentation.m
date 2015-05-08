#import "OBAPresentation.h"

@implementation OBAPresentation

+ (NSString*) getRouteShortNameForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    if (arrivalAndDeparture.routeShortName) {
        return arrivalAndDeparture.routeShortName;
    }
    else {
        OBATripV2* trip = arrivalAndDeparture.trip;

        if (trip.routeShortName) {
            return trip.routeShortName;
        }
        else {
            return trip.route.shortName ?: trip.route.longName;
        }
    }
}

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