#import "OBATripV2.h"
#import "NSObject+OBADescription.h"

@implementation OBATripV2

- (OBARouteV2*)route {
    OBAReferencesV2 * refs = self.references;
    return [refs getRouteForId:self.routeId];
}

- (NSString*)asLabel {
    NSString * rShortName = self.routeShortName ?: self.route.safeShortName;
    NSString *headsign = nil;

    if (self.tripHeadsign) {
        headsign = self.tripHeadsign;
    }
    else if (self.route.longName) {
        headsign = self.route.longName;
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
