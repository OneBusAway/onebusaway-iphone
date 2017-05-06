//
//  OBAModelPersistenceLayer.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/3/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;

@class CLLocation;
@class OBARegionV2;
@class OBATripDeepLink;
@class OBAAlarm;
@class OBAArrivalAndDepartureV2;

NS_ASSUME_NONNULL_BEGIN

@protocol OBAModelPersistenceLayer <NSObject>
@property(nonatomic,assign) BOOL hideFutureLocationWarnings;
@property(nonatomic,assign) BOOL ungroupedBookmarksOpen;
@property(nonatomic,assign) BOOL shareRegionPII;
@property(nonatomic,assign) BOOL shareLocationPII;
@property(nonatomic,assign) BOOL shareLogsPII;

- (NSArray*) readBookmarks;
- (void) writeBookmarks:(NSArray*)source;

- (NSArray*) readBookmarkGroups;
- (void) writeBookmarkGroups:(NSArray*)source;

- (NSArray*) readMostRecentStops;
- (void) writeMostRecentStops:(NSArray*)source;

- (NSDictionary*) readStopPreferences;
- (void) writeStopPreferences:(NSDictionary*)stopPreferences;

- (CLLocation * _Nullable) readMostRecentLocation;
- (void) writeMostRecentLocation:(CLLocation*)mostRecentLocation;

// Service Alerts

- (NSSet*)readVisistedSituationIds;
- (void)writeVisistedSituationIds:(NSSet*)situationIds;

// Regions

- (OBARegionV2 * _Nullable) readOBARegion;
- (void)writeOBARegion:(OBARegionV2*)region;

- (BOOL) readSetRegionAutomatically;
- (void) writeSetRegionAutomatically:(BOOL)setRegionAutomatically;

- (NSSet<OBARegionV2*>*)customRegions;
- (void)addCustomRegion:(OBARegionV2*)region;
- (void)removeCustomRegion:(OBARegionV2*)region;

// Shared Trips/Deep Links

- (NSSet<OBATripDeepLink*>*)sharedTrips;
- (void)addSharedTrip:(OBATripDeepLink*)sharedTrip;
- (void)removeSharedTrip:(OBATripDeepLink*)sharedTrip;

// Alarms
- (NSArray<OBAAlarm*>*)alarms;
- (OBAAlarm*)alarmForKey:(NSString*)alarmKey;
- (void)addAlarm:(OBAAlarm*)alarm;
- (void)removeAlarmWithKey:(NSString*)alarmKey;

@end

NS_ASSUME_NONNULL_END
