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

#import <OBAKit/OBATripStatusV2.h>
#import <OBAKit/NSObject+OBADescription.h>

@implementation OBATripStatusV2

- (OBATripV2*) activeTrip {
    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.activeTripId];
}

- (OBATripInstanceRef*) tripInstance {
    return [OBATripInstanceRef tripInstance:self.activeTripId serviceDate:self.serviceDate vehicleId:self.vehicleId];
}

- (NSString*)formattedScheduleDeviation {
    NSInteger sd = self.scheduleDeviation;
    NSString *label = @" ";

    if (sd > 0) {
        label = NSLocalizedString(@"msg_space_late", @"sd > 0");
    }
    else if (sd < 0) {
        label = NSLocalizedString(@"msg_space_early", @"sd < 0");
        sd = -sd;
    }

    NSInteger mins = sd / 60;
    NSInteger secs = sd % 60;

    return [NSString stringWithFormat:@"%@: %ldm %lds%@", NSLocalizedString(@"msg_schedule_deviation", @"cell.textLabel.text"), (long)mins, (long)secs, label];
}

- (NSString*)description {
    return [self oba_description:@[@"activeTripId", @"activeTrip", @"serviceDate", @"frequency", @"location", @"predicted", @"scheduleDeviation", @"vehicleId", @"lastUpdateTime", @"lastKnownLocation", @"tripInstance"]];
}
@end
