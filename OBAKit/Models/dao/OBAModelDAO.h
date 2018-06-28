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

#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBAAlarm.h>
#import <OBAKit/OBABookmarkV2.h>
#import <OBAKit/OBAStopAccessEventV2.h>
#import <OBAKit/OBAStopPreferencesV2.h>
#import <OBAKit/OBAServiceAlertsModel.h>
#import <OBAKit/OBARegionV2.h>
#import <OBAKit/OBAModelPersistenceLayer.h>
#import <OBAKit/OBATripDeepLink.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OBAUngroupedBookmarksIdentifier;
extern NSString * const OBAMostRecentStopsChangedNotification;
extern NSString * const OBARegionDidUpdateNotification;

@interface OBAModelDAO : NSObject
@property(nonatomic,strong,readonly) NSArray<OBABookmarkV2*> *bookmarksForCurrentRegion;

/**
 Comprises all of the bookmarks for the current region that can be displayed on a map. i.e., they have lat/lng, and a stop ID.
 */
@property(nonatomic,strong,readonly) NSArray<OBABookmarkV2*> *mappableBookmarksForCurrentRegion;
@property(strong,nonatomic,readonly) NSArray<OBABookmarkV2*> *ungroupedBookmarks;

/**
 All bookmark groups.
 */
@property(nonatomic,strong,readonly) NSArray<OBABookmarkGroup*> *bookmarkGroups;

/**
 All bookmark groups created by the user. (i.e. not the Today Widget bookmark group.)
 */
@property(nonatomic,strong,readonly) NSArray<OBABookmarkGroup*> *userCreatedBookmarkGroups;

/**
 The Today View Controller bookmark group.
 */
@property(nonatomic,strong,readonly) OBABookmarkGroup *todayBookmarkGroup;

@property(strong,nonatomic,readonly) NSArray<OBAStopAccessEventV2*> * mostRecentStops;
@property(nonatomic,copy) CLLocation *mostRecentLocation;
@property(nonatomic,assign) BOOL hideFutureLocationWarnings;
@property(nonatomic,assign) BOOL ungroupedBookmarksOpen;

- (instancetype)initWithModelPersistenceLayer:(id<OBAModelPersistenceLayer>)persistenceLayer;

// Bookmarks
@property(nonatomic,assign,readonly) NSUInteger allBookmarksCount;

- (NSArray<OBABookmarkV2*>*)bookmarksMatchingPredicate:(NSPredicate*)predicate;
- (NSArray<OBABookmarkV2*>*)mappableBookmarksMatchingString:(NSString*)matching;
- (nullable OBABookmarkV2*)bookmarkForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrival;
- (void)saveBookmark:(OBABookmarkV2*)bookmark;
- (void)moveBookmark:(NSUInteger)startIndex to:(NSUInteger)endIndex;
- (void)removeBookmark:(OBABookmarkV2*)bookmark;
- (nullable OBABookmarkV2*)bookmarkAtIndex:(NSUInteger)index inGroup:(nullable OBABookmarkGroup*)group;
- (void)moveBookmark:(OBABookmarkV2*)bookmark toIndex:(NSUInteger)index inGroup:(nullable OBABookmarkGroup*)group;
- (void)moveBookmark:(OBABookmarkV2*)bookmark toGroup:(nullable OBABookmarkGroup*)group;
- (void)moveBookmark:(NSUInteger)startIndex to:(NSUInteger)endIndex inGroup:(OBABookmarkGroup*)group;

// Bookmark Groups

- (void)moveBookmarkGroup:(OBABookmarkGroup*)bookmarkGroup toIndex:(NSUInteger)index;
- (void)saveBookmarkGroup:(OBABookmarkGroup *)bookmarkGroup;
- (void)removeBookmarkGroup:(OBABookmarkGroup*)bookmarkGroup;
- (void)persistGroups;

// Stop Preferences

- (OBAStopPreferencesV2*)stopPreferencesForStopWithId:(NSString*)stopId;
- (void)setStopPreferences:(OBAStopPreferencesV2*)preferences forStopWithId:(NSString*)stopId;

// Service Alerts

- (BOOL)isVisitedSituationWithId:(NSString*)situationId;
- (void)setVisited:(BOOL)visited forSituationWithId:(NSString*)situationId;
- (OBAServiceAlertsModel*) getServiceAlertsModelForSituations:(NSArray*)situations;

// Recent Stops

- (void)clearMostRecentStops;
- (void)viewedArrivalsAndDeparturesForStop:(OBAStopV2*)stop;
- (void)removeRecentStop:(OBAStopAccessEventV2*)recentStop;
- (NSArray<OBAStopAccessEventV2*>*)recentStopsMatchingString:(NSString*)matching;

/**
 Creates and returns a sorted list of recent stops within one mile of the specified coordinate.

 @param coordinate The coordinate from which to return recent stops.
 @return An array of recent stop objects.
 */
- (NSArray<OBAStopAccessEventV2*>*)recentStopsNearCoordinate:(CLLocationCoordinate2D)coordinate;

// Regions

@property(nonatomic,strong,nullable) OBARegionV2 *currentRegion;
@property(nonatomic,assign) BOOL automaticallySelectRegion;

- (NSArray<OBARegionV2*>*)customRegions;
- (void)addCustomRegion:(OBARegionV2*)region;
- (void)removeCustomRegion:(OBARegionV2*)region;

// PII/Privacy

@property(nonatomic,assign) BOOL shareRegionPII;
@property(nonatomic,assign) BOOL shareLocationPII;
@property(nonatomic,assign) BOOL shareLogsPII;

// Shared Trips

@property(nonatomic,copy,readonly) NSArray<OBATripDeepLink*> *sharedTrips;
- (void)addSharedTrip:(OBATripDeepLink*)sharedTrip;
- (void)removeSharedTrip:(OBATripDeepLink*)sharedTrip;
- (void)clearSharedTrips;
- (void)clearSharedTripsOlderThan24Hours;

// Alarms
@property(nonatomic,copy,readonly) NSArray<OBAAlarm*> *alarms;
- (OBAAlarm*)alarmForKey:(NSString*)alarmKey;
- (void)addAlarm:(OBAAlarm*)alarm;
- (void)removeAlarmWithKey:(NSString*)alarmKey;
- (void)clearExpiredAlarms;
@end

NS_ASSUME_NONNULL_END
