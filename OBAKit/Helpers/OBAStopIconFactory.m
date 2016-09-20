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

#import <OBAKit/OBAStopIconFactory.h>
#import <OBAKit/OBARouteV2.h>

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

// TODO: what about "metro"?
+ (NSString *)getRouteIconTypeForStop:(OBAStopV2 *)stop {
    OBARouteType routeType = stop.firstAvailableRouteTypeForStop;

    switch (routeType) {
        case OBARouteTypeFerry:
            return @"Ferry";
        case OBARouteTypeTrain:
            return @"Rail";
        case OBARouteTypeLightRail:
            return @"LightRail";
        default:
            return @"Bus";
    }
}

@end
