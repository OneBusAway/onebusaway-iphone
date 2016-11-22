/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
        headsign = NSLocalizedString(@"msg_headed_somewhere_dots",@"");
    }

    return [NSString stringWithFormat:@"%@ - %@",rShortName, headsign];
}

- (NSString*)description {
    return [self oba_description:@[@"tripId", @"routeId", @"routeShortName", @"tripShortName", @"tripHeadsign", @"serviceId", @"shapeId", @"directionId", @"blockId", @"route", @"asLabel"]];
}

@end
