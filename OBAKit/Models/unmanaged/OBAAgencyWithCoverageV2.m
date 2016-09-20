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

#import <OBAKit/OBAAgencyWithCoverageV2.h>
#import <OBAKit/NSObject+OBADescription.h>

@implementation OBAAgencyWithCoverageV2

- (OBAAgencyV2*) agency {
    OBAReferencesV2 * refs = [self references];
    return [refs getAgencyForId:self.agencyId];
}

- (NSComparisonResult) compareUsingAgencyName:(OBAAgencyWithCoverageV2*)obj {
    NSString * nameA = [self.agency name];
    NSString * nameB = [obj.agency name];
    return [nameA compare:nameB options:NSNumericSearch];
}

- (OBARegionBoundsV2*)regionBounds {

    if (self.latSpan == 0 || self.lonSpan == 0) {
        return nil;
    }

    if (self.lat == 0 || self.lon == 0) {
        return nil;
    }

    OBARegionBoundsV2 *regionBounds = [[OBARegionBoundsV2 alloc] init];
    regionBounds.lat = self.lat;
    regionBounds.latSpan = self.latSpan;
    regionBounds.lon = self.lon;
    regionBounds.lonSpan = self.lonSpan;
    return regionBounds;
}

- (NSString*)description {
    return [self oba_description:@[@"agencyId", @"agency"] keyPaths:@[@"regionBounds"]];
}

@end
