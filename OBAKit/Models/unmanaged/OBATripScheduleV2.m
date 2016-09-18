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

#import <OBAKit/OBATripScheduleV2.h>

@implementation OBATripScheduleV2

- (OBATripV2*)previousTrip {
    if (!self.previousTripId) {
        return nil;
    }

    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.previousTripId];
}

- (OBATripV2*)nextTrip {
    if (!self.nextTripId) {
        return nil;
    }

    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.nextTripId];
}

@end
