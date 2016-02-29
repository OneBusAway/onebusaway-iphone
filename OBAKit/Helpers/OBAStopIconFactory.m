/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAStopIconFactory.h"
#import "OBARouteV2.h"

@implementation OBAStopIconFactory

+ (UIImage *)getIconForStop:(OBAStopV2 *)stop {
    NSString *routeIconType = [self getRouteIconTypeForStop:stop];
    NSString *direction = @"";

    if (stop.direction) {
        direction = stop.direction;
    }

    NSString *key = [NSString stringWithFormat:@"%@StopIcon%@", routeIconType, direction];

    return [UIImage imageNamed:key];
}

#pragma mark - Private

+ (NSString *)getRouteIconTypeForStop:(OBAStopV2 *)stop {
    NSMutableSet *routeTypes = [NSMutableSet set];

    for (OBARouteV2 *route in stop.routes) {
        if (route.routeType) {
            [routeTypes addObject:route.routeType];
        }
    }

    return [self getRouteIconTypeForRouteTypes:routeTypes];
}

// TODO: what about "metro"?
+ (NSString *)getRouteIconTypeForRouteTypes:(NSSet *)routeTypes {
    if ([routeTypes containsObject:@(OBARouteTypeFerry)]) {
        return @"Ferry";
    }
    else if ([routeTypes containsObject:@(OBARouteTypeTrain)]) {
        return @"Rail";
    }
    else if ([routeTypes containsObject:@(OBARouteTypeLightRail)]) {
        return @"LightRail";
    }
    else {
        return @"Bus";
    }
}

@end