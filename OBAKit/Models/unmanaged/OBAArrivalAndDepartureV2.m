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

#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBADateHelpers.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/NSObject+OBADescription.h>
#import <OBAKit/OBAAlarm.h>

@interface OBAArrivalAndDepartureV2 ()
@property(nonatomic,strong) NSMutableArray *situationIds;

@property(nonatomic,assign) long long scheduledArrivalTime;
@property(nonatomic,assign) long long predictedArrivalTime;
@property(nonatomic,assign,readonly) long long bestArrivalTime;
@property(nonatomic,assign) long long scheduledDepartureTime;
@property(nonatomic,assign) long long predictedDepartureTime;
@property(nonatomic,assign,readonly) long long bestDepartureTime;
@property(nonatomic,assign) BOOL predicted;
@end

@implementation OBAArrivalAndDepartureV2

#pragma mark - Class Helpers

+ (BOOL)hasScheduledDepartures:(NSArray<OBAArrivalAndDepartureV2*>*)departures {
    for (OBAArrivalAndDepartureV2* dep in departures) {
        if (!dep.hasRealTimeData) {
            return YES;
        }
    }
    return NO;
}


#pragma mark - Instance Methods

- (instancetype)init {
    self = [super init];
    if (self) {
        _situationIds = [[NSMutableArray alloc] init];
    }
    return self;
}

- (OBARouteV2*) route {
    OBAReferencesV2 * refs = [self references];
    return [refs getRouteForId:self.routeId];
}

- (OBAStopV2*) stop {
    OBAReferencesV2 * refs = [self references];
    return [refs getStopForId:self.stopId];
}

- (OBATripV2*) trip {
    OBAReferencesV2 * refs = [self references];
    return [refs getTripForId:self.tripId];
}

- (NSString*)tripHeadsign {

    NSString *headsign = nil;

    OBATripV2 *trip = self.trip;
    OBARouteV2 *route = trip.route;

    // TODO: figure out how an NSNull is slipping through the
    // model layer :( Maybe this is an indication that we
    // need to move to a more modern modeling framework.
    if (![_tripHeadsign isEqual:NSNull.null] && _tripHeadsign.length > 0) {
        headsign = _tripHeadsign;
    }
    else if (trip.tripHeadsign) {
        headsign = trip.tripHeadsign;
    }
    else if (route.longName) {
        headsign = route.longName;
    }
    else if (route.shortName) {
        headsign = route.shortName;
    }

    if (!headsign || [headsign isEqual:NSNull.null]) {
        return nil;
    }

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[a-z]" options:(NSRegularExpressionOptions)0 error:nil];
    if ([regex numberOfMatchesInString:headsign options:(NSMatchingOptions)0 range:NSMakeRange(0, headsign.length)] > 0) {
        // Headsign contains a mix of uppercase and lowercase letters. Let it be.
        return headsign;
    }
    else {
        // No lowercase letters anywhere in the headsign.
        // Return a Cap Case String in order to prevent SCREAMING CAPS.
        return headsign.capitalizedString;
    }
}

- (OBAArrivalAndDepartureInstanceRef*)instance {
    return [[OBAArrivalAndDepartureInstanceRef alloc] initWithTripInstance:self.tripInstance stopId:self.stopId stopSequence:self.stopSequence];
}

- (OBATripInstanceRef*)tripInstance {
    return [OBATripInstanceRef tripInstance:self.tripId serviceDate:self.serviceDate vehicleId:self.tripStatus.vehicleId];
}

- (long long) bestArrivalTime {
    return self.predictedArrivalTime == 0 ? self.scheduledArrivalTime : self.predictedArrivalTime;
}

- (long long) bestDepartureTime {
    return self.predictedDepartureTime == 0 ? self.scheduledDepartureTime : self.predictedDepartureTime;
}

- (NSDate*)scheduledDepartureDate {
    return [OBADateHelpers dateWithMillisecondsSince1970:self.scheduledDepartureTime];
}

- (BOOL)hasRealTimeData {
    return self.predictedDepartureTime > 0;
}

#pragma mark - OBAHasServiceAlerts

- (NSArray<OBASituationV2*>*)situations {
    NSMutableArray *rSituations = [NSMutableArray array];

    for (NSString *situationId in self.situationIds) {
        OBASituationV2 *situation = [self.references getSituationForId:situationId];
        if (situation) {
            [rSituations addObject:situation];
        }
    }

    return [NSArray arrayWithArray:rSituations];
}

- (void)addSituationId:(NSString*)situationId {
    [self.situationIds addObject:situationId];
}

#pragma mark - Public methods

- (OBADepartureStatus)departureStatus {
    if (!self.hasRealTimeData) {
        return OBADepartureStatusUnknown;
    }

    double diff = (self.predictedDepartureTime - self.scheduledDepartureTime) / (1000.0 * 60.0);

    if (diff < -1.5) {
        return OBADepartureStatusEarly;
    }
    else if (diff < 1.5) {
        return OBADepartureStatusOnTime;
    }
    else {
        return OBADepartureStatusDelayed;
    }
}

- (NSString*)bestAvailableName {
    if (self.routeShortName) {
        return self.routeShortName;
    }

    OBATripV2 *trip = self.trip;
    OBARouteV2 *route = trip.route;

    if (trip.routeShortName) {
        return trip.routeShortName;
    }
    else if (route.shortName) {
        return route.shortName;
    }
    else {
        return route.longName;
    }
}

- (NSString*)bestAvailableNameWithHeadsign {
    NSString *name = [self bestAvailableName];
    NSString *headsign = [self tripHeadsign];

    if (!headsign) {
        return name;
    }

    return [NSString stringWithFormat:OBALocalized(@"text_route_to_orientation_params", @"<Route Number> to <Location>. e.g. 10 to Downtown Seattle"), name, self.tripHeadsign];
}

- (double)predictedDepatureTimeDeviationFromScheduleInMinutes {

    if (self.departureStatus == OBADepartureStatusUnknown) {
        return NAN;
    }
    else {
        return (self.predictedDepartureTime - self.scheduledDepartureTime) / (1000.0 * 60.0);
    }
}

- (NSTimeInterval)timeIntervalUntilBestDeparture {
    return self.bestArrivalDepartureDate.timeIntervalSinceNow;
}

- (NSInteger)minutesUntilBestDeparture {
    return (NSInteger)(self.timeIntervalUntilBestDeparture / 60.0);
}

- (BOOL)routesAreEquivalent:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    OBAGuard(arrivalAndDeparture) else {
        return NO;
    }

    return [self.bookmarkKey isEqual:arrivalAndDeparture.bookmarkKey];
}

- (OBAArrivalDepartureState)arrivalDepartureState {
    if (self.stopSequence != 0) {
        return OBAArrivalDepartureStateArriving;
    }
    else {
        return OBAArrivalDepartureStateDeparting;
    }
}

- (NSDate*)bestArrivalDepartureDate {
    if (self.arrivalDepartureState == OBAArrivalDepartureStateArriving) {
        return [OBADateHelpers dateWithMillisecondsSince1970:self.bestArrivalTime];
    }
    else {
        return [OBADateHelpers dateWithMillisecondsSince1970:self.bestDepartureTime];
    }
}

#pragma mark - Compare

- (NSComparisonResult)compareRouteName:(OBAArrivalAndDepartureV2*)dep {
    return [self.routeShortName compare:dep.routeShortName options:NSNumericSearch];
}

#pragma mark - Keys

- (NSString*)bookmarkKey {
    return [NSString stringWithFormat:@"%@_%@_%@", self.bestAvailableName, self.tripHeadsign.lowercaseString, self.routeId];
}

- (NSString*)alarmKey {
    return [OBAAlarm alarmKeyForStopID:self.stopId tripID:self.tripId serviceDate:self.serviceDate vehicleID:self.tripStatus.vehicleId stopSequence:self.stopSequence];
}

#pragma mark - NSObject

- (NSUInteger)hash {
    return self.bookmarkKey.hash;
}

- (BOOL)isEqual:(OBAArrivalAndDepartureV2*)object {
    if (![object isKindOfClass:OBAArrivalAndDepartureV2.class]) {
        return NO;
    }

    return [self routesAreEquivalent:object];
}

- (NSString*)description {
    return [self oba_description:@[@"routeId", @"route", @"routeShortName", @"tripId", @"trip", @"tripHeadsign", @"serviceDate", @"instance", @"tripInstance", @"stopId", @"stop", @"stopSequence", @"tripStatus", @"frequency", @"predicted", @"scheduledArrivalTime", @"predictedArrivalTime", @"bestArrivalTime", @"scheduledDepartureTime", @"predictedDepartureTime", @"bestDepartureTime", @"distanceFromStop", @"numberOfStopsAway"]];
}

@end
