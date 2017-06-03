//
//  OBAAlarm.m
//  OBAKit
//
//  Created by Aaron Brethorst on 1/13/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAAlarm.h>
#import <OBAKit/NSCoder+OBAAdditions.h>

NSInteger const OBAAlarmIncrementsInMinutes = 5;

@implementation OBAAlarm

- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture regionIdentifier:(NSInteger)regionIdentifier timeIntervalBeforeDeparture:(NSTimeInterval)timeIntervalBeforeDeparture {
    self = [super init];

    if (self) {
        _timeIntervalBeforeDeparture = timeIntervalBeforeDeparture;
        _regionIdentifier = regionIdentifier;
        _stopID = [arrivalAndDeparture.stopId copy];
        _tripID = [arrivalAndDeparture.tripId copy];
        _serviceDate = arrivalAndDeparture.serviceDate;
        _vehicleID = [arrivalAndDeparture.tripStatus.vehicleId copy];
        _stopSequence = arrivalAndDeparture.stopSequence;
        _title = [arrivalAndDeparture.bestAvailableNameWithHeadsign copy];
        _scheduledDeparture = [arrivalAndDeparture.scheduledDepartureDate copy];
        _estimatedDeparture = [arrivalAndDeparture.bestArrivalDepartureDate copy];
    }

    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self) {
        _timeIntervalBeforeDeparture = [aDecoder oba_decodeDouble:@selector(timeIntervalBeforeDeparture)];
        _alarmURL = [aDecoder oba_decodeObject:@selector(alarmURL)];
        _regionIdentifier = [aDecoder oba_decodeInteger:@selector(regionIdentifier)];
        _stopID = [aDecoder oba_decodeObject:@selector(stopID)];
        _tripID = [aDecoder oba_decodeObject:@selector(tripID)];
        _serviceDate = [aDecoder oba_decodeInt64:@selector(serviceDate)];
        _vehicleID = [aDecoder oba_decodeObject:@selector(vehicleID)];
        _stopSequence = [aDecoder oba_decodeInteger:@selector(stopSequence)];
        _title = [aDecoder oba_decodeObject:@selector(title)];
        _scheduledDeparture = [aDecoder oba_decodeObject:@selector(scheduledDeparture)];
        _estimatedDeparture = [aDecoder oba_decodeObject:@selector(estimatedDeparture)];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder oba_encodeDouble:_timeIntervalBeforeDeparture forSelector:@selector(timeIntervalBeforeDeparture)];
    [aCoder oba_encodeObject:_alarmURL forSelector:@selector(alarmURL)];
    [aCoder oba_encodeInteger:_regionIdentifier forSelector:@selector(regionIdentifier)];
    [aCoder oba_encodeObject:_stopID forSelector:@selector(stopID)];
    [aCoder oba_encodeObject:_tripID forSelector:@selector(tripID)];
    [aCoder oba_encodeInt64:_serviceDate forSelector:@selector(serviceDate)];
    [aCoder oba_encodeObject:_vehicleID forSelector:@selector(vehicleID)];
    [aCoder oba_encodeInteger:_stopSequence forSelector:@selector(stopSequence)];
    [aCoder oba_encodePropertyOnObject:self withSelector:@selector(title)];
    [aCoder oba_encodePropertyOnObject:self withSelector:@selector(scheduledDeparture)];
    [aCoder oba_encodePropertyOnObject:self withSelector:@selector(estimatedDeparture)];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    OBAAlarm *alarm = [[self.class alloc] init];
    alarm->_timeIntervalBeforeDeparture = _timeIntervalBeforeDeparture;
    alarm->_alarmURL = [_alarmURL copyWithZone:zone];
    alarm->_regionIdentifier = _regionIdentifier;
    alarm->_stopID = [_stopID copyWithZone:zone];
    alarm->_tripID = [_tripID copyWithZone:zone];
    alarm->_serviceDate = _serviceDate;
    alarm->_vehicleID = [_vehicleID copyWithZone:zone];
    alarm->_stopSequence = _stopSequence;
    alarm->_title = [_title copy];
    alarm->_scheduledDeparture = [_scheduledDeparture copyWithZone:zone];
    alarm->_estimatedDeparture = [_estimatedDeparture copyWithZone:zone];
    return alarm;
}

#pragma mark - Alarm Key

- (NSString*)alarmKey {
    return [self.class alarmKeyForStopID:self.stopID tripID:self.tripID serviceDate:self.serviceDate vehicleID:self.vehicleID stopSequence:self.stopSequence];
}

+ (NSString*)alarmKeyForStopID:(NSString *)stopID tripID:(NSString *)tripID serviceDate:(long long)serviceDate vehicleID:(NSString *)vehicleID stopSequence:(NSInteger)stopSequence {
    return [NSString stringWithFormat:@"%@_%@_%@_%@_%@", stopID, tripID, @(serviceDate), vehicleID, @(stopSequence)];
}
@end
