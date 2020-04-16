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
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBADateHelpers.h>

@implementation OBATripStatusV2

- (OBATripV2*) activeTrip {
    OBAReferencesV2 * refs = self.references;
    return [refs getTripForId:self.activeTripId];
}

- (OBATripInstanceRef*) tripInstance {
    return [OBATripInstanceRef tripInstance:self.activeTripId serviceDate:self.serviceDate vehicleId:self.vehicleId];
}

- (NSDate*)lastUpdateDate {
    return [OBADateHelpers dateWithMillisecondsSince1970:self.lastUpdateTime];
}

- (NSString*)formattedScheduleDeviation {
    NSInteger sd = self.scheduleDeviation;
    NSString *label = @" ";

    if (sd > 0) {
        label = OBALocalized(@"msg_space_late", @"sd > 0");
    }
    else if (sd < 0) {
        label = OBALocalized(@"msg_space_early", @"sd < 0");
        sd = -sd;
    }

    NSInteger mins = sd / 60;
    NSInteger secs = sd % 60;

    return [NSString stringWithFormat:@"%ldm %lds%@", (long)mins, (long)secs, label];
}

- (NSString*)description {
    return [self oba_description:@[@"activeTripId", @"activeTrip", @"serviceDate", @"frequency", @"location", @"predicted", @"scheduleDeviation", @"vehicleId", @"lastUpdateTime", @"lastKnownLocation", @"tripInstance", @"closestStopID"]];
}

- (CGFloat)orientationInRadians {
    return self.orientation * M_PI / 180.f;
}

- (OBATripStatusModifier)statusModifier {
    if ([self.status isEqualToString:@"default"]) {
        return OBATripStatusModifierDefault;
    } else if ([self.status isEqualToString:@"SCHEDULED"]) {
        return OBATripStatusModifierScheduled;
    } else if ([self.status isEqualToString:@"CANCELED"]) {
        return OBATripStatusModifierCanceled;
    } else {
        return OBATripStatusModifierOther;
    }
}

- (BOOL)isCanceled {
    return (self.statusModifier == OBATripStatusModifierCanceled);
}

#pragma mark - MKAnnotation

- (CLLocationCoordinate2D)coordinate {
    return self.position.coordinate;
}

- (NSString*)title {
    return self.activeTrip.asLabel;
}

- (NSString*)subtitle {
    if (self.lastUpdateTime == 0) {
        return NSLocalizedString(@"trip_status.no_realtime_data_message", @"Returned by -[OBATripStatusV2 subtitle] when no real time data is available.");
    }

    NSUInteger interval = (NSUInteger)ABS([self.lastUpdateDate timeIntervalSinceNow]);
    NSUInteger minutes = interval / 60;
    NSUInteger seconds = interval % 60;

    return [NSString stringWithFormat:NSLocalizedString(@"trip_status.last_report_format", @"e.g. Last report: 2m 43s ago"), @(minutes), @(seconds)];
}

@end
