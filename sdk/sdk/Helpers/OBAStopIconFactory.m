#import "OBAStopIconFactory.h"
#import "OBARouteV2.h"

@implementation OBAStopIconFactory

- (UIImage *)getIconForStop:(OBAStopV2 *)stop {
    return [self getIconForStop:stop includeDirection:YES];
}

- (UIImage *)getIconForStop:(OBAStopV2 *)stop includeDirection:(BOOL)includeDirection {
    NSString *routeIconType = [self getRouteIconTypeForStop:stop];
    NSString *direction = @"";

    if (includeDirection && stop.direction) {
        direction = stop.direction;
    }

    NSString *key = [NSString stringWithFormat:@"%@StopIcon%@", routeIconType, direction];

    return [UIImage imageNamed:key];
}

- (UIImage *)getModeIconForRoute:(OBARouteV2 *)route {
    return [self getModeIconForRoute:route selected:NO];
}

- (UIImage *)getModeIconForRoute:(OBARouteV2 *)route selected:(BOOL)selected {
    NSString *type = [self getRouteIconTypeForRoute:route];

    return [self getModeIconForRouteIconType:type selected:selected];
}

- (UIImage *)getModeIconForRouteIconType:(NSString *)routeType selected:(BOOL)selected {
    NSString *format = selected ? @"Mode-%@-Selected" : @"Mode-%@";

    return [UIImage imageNamed:[NSString stringWithFormat:format, routeType]];
}

- (NSString *)getRouteIconTypeForRoutes:(NSArray *)routes {
    NSMutableSet *routeTypes = [NSMutableSet set];

    for (OBARouteV2 *route in routes) {
        if (route.routeType) {
            [routeTypes addObject:route.routeType];
        }
    }

    return [self getRouteIconTypeForRouteTypes:routeTypes];
}

#pragma mark - Private

- (NSString *)getRouteIconTypeForStop:(OBAStopV2 *)stop {
    NSMutableSet *routeTypes = [NSMutableSet set];

    for (OBARouteV2 *route in stop.routes) {
        if (route.routeType) {
            [routeTypes addObject:route.routeType];
        }
    }

    return [self getRouteIconTypeForRouteTypes:routeTypes];
}

- (NSString *)getRouteIconTypeForRouteTypes:(NSSet *)routeTypes {
    // Heay rail dominations
    if ([routeTypes containsObject:@4]) {
        return @"Ferry";
    }
    else if ([routeTypes containsObject:@2]) {
        return @"Rail";
    }
    else if ([routeTypes containsObject:@0]) {
        return @"LightRail";
    }
    else {
        return @"Bus";
    }
}

- (NSString *)getRouteIconTypeForRoute:(OBARouteV2 *)route {
    switch (route.routeType.integerValue) {
        case 4:
            return @"Ferry";

        case 2:
            return @"Rail";

        case 0:
            return @"LightRail";

        default:
            return @"Bus";
    }
}

@end