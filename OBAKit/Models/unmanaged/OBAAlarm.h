//
//  OBAAlarm.h
//  OBAKit
//
//  Created by Aaron Brethorst on 1/13/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBAArrivalAndDepartureConvertible.h>

NS_ASSUME_NONNULL_BEGIN

extern NSInteger const OBAAlarmIncrementsInMinutes;

@interface OBAAlarm : NSObject<NSCoding, NSCopying,OBAArrivalAndDepartureConvertible>

/**
 The number of seconds before departure this alarm is scheduled to fire.
 */
@property(nonatomic, assign) NSTimeInterval timeIntervalBeforeDeparture;

/**
 The alarm URL on the obaco server. The alarm can be canceled by sending
 an HTTP DELETE request to this URL.
 */
@property(nonatomic, copy, nullable) NSURL *alarmURL;

/**
 Corresponds to `identifier` on `OBARegionV2`.
 */
@property(nonatomic, assign) NSInteger regionIdentifier;

/**
 the stop id of the stop the vehicle is arriving at
 */
@property(nonatomic, copy) NSString *stopID;

/**
 the trip id for the arriving vehicle
 */
@property(nonatomic,copy) NSString *tripID;

@property(nonatomic,copy) NSDate *scheduledDeparture;

@property(nonatomic,assign) long long serviceDate;

@property(nonatomic,copy) NSString *vehicleID;

/**
 the index of the stop into the sequence of stops that make up the trip for this arrival
 */
@property(nonatomic,assign) NSInteger stopSequence;

@property(nonatomic,copy,readonly) NSString *alarmKey;

/**
 A title for this alarm suitable to displaying to the user.
 */
@property(nonatomic,copy) NSString *title;

- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture regionIdentifier:(NSInteger)regionIdentifier timeIntervalBeforeDeparture:(NSTimeInterval)timeIntervalBeforeDeparture;

+ (NSString*)alarmKeyForStopID:(NSString*)stopID tripID:(NSString*)tripID serviceDate:(long long)serviceDate vehicleID:(NSString*)vehicleID stopSequence:(NSInteger)stopSequence;

@end

NS_ASSUME_NONNULL_END
