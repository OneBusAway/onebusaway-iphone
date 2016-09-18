#import <OBAKit/OBATripV2.h>
#import <OBAKit/NSObject+OBADescription.h>

@implementation OBATripV2

- (OBARouteV2*)route {
    OBAReferencesV2 * refs = self.references;
    return [refs getRouteForId:self.routeId];
}

- (NSString*)asLabel {
    OBARouteV2 *route = self.route;
    NSString * rShortName = self.routeShortName ?: route.safeShortName;
    NSString *headsign = nil;

    if (self.tripHeadsign) {
        headsign = self.tripHeadsign;
    }
    else if (route.longName) {
        headsign = route.longName;
    }
    else {
        headsign = NSLocalizedString(@"Headed somewhere...",@"");
    }

    return [NSString stringWithFormat:@"%@ - %@",rShortName, headsign];
}

- (NSString*)description {
    return [self oba_description:@[@"tripId", @"routeId", @"routeShortName", @"tripShortName", @"tripHeadsign", @"serviceId", @"shapeId", @"directionId", @"blockId", @"route", @"asLabel"]];
}

@end
