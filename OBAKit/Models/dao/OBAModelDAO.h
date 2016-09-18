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
#import <OBAKit/OBABookmarkV2.h>
#import <OBAKit/OBAStopAccessEventV2.h>
#import <OBAKit/OBAStopPreferencesV2.h>
#import <OBAKit/OBAServiceAlertsModel.h>
#import <OBAKit/OBARegionV2.h>
#import <OBAKit/OBAModelPersistenceLayer.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OBAUngroupedBookmarksIdentifier;
extern NSString * const OBAMostRecentStopsChangedNotification;
extern NSString * const OBARegionDidUpdateNotification;

@interface OBAModelDAO : NSObject
@property(nonatomic,strong,readonly) NSArray<OBABookmarkV2*> *bookmarksForCurrentRegion;
@property(strong,nonatomic,readonly) NSArray<OBABookmarkV2*> *ungroupedBookmarks;
@property(strong,nonatomic,readonly) NSArray<OBABookmarkGroup*> *bookmarkGroups;
@property(strong,nonatomic,readonly) NSArray<OBAStopAccessEventV2*> * mostRecentStops;
@property(nonatomic,copy) CLLocation *mostRecentLocation;
@property(nonatomic,strong,nullable) OBARegionV2 *currentRegion;
@property(nonatomic,assign) BOOL hideFutureLocationWarnings;
@property(nonatomic,assign) BOOL ungroupedBookmarksOpen;
@property(nonatomic,assign) BOOL automaticallySelectRegion;

- (instancetype)initWithModelPersistenceLayer:(id<OBAModelPersistenceLayer>)persistenceLayer;

- (NSArray<OBABookmarkV2*>*)bookmarksMatchingPredicate:(NSPredicate*)predicate;
- (nullable OBABookmarkV2*)bookmarkForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrival;
- (void)saveBookmark:(OBABookmarkV2*)bookmark;
- (void)moveBookmark:(NSUInteger)startIndex to:(NSUInteger)endIndex;
- (void)removeBookmark:(OBABookmarkV2*)bookmark;

- (nullable OBABookmarkV2*)bookmarkAtIndex:(NSUInteger)index inGroup:(nullable OBABookmarkGroup*)group;
- (void)moveBookmark:(OBABookmarkV2*)bookmark toIndex:(NSUInteger)index inGroup:(nullable OBABookmarkGroup*)group;
- (void)moveBookmark:(OBABookmarkV2*)bookmark toGroup:(nullable OBABookmarkGroup*)group;
- (void)moveBookmark:(NSUInteger)startIndex to:(NSUInteger)endIndex inGroup:(OBABookmarkGroup*)group;

- (void)moveBookmarkGroup:(OBABookmarkGroup*)bookmarkGroup toIndex:(NSUInteger)index;
- (void)saveBookmarkGroup:(OBABookmarkGroup *)bookmarkGroup;
- (void)removeBookmarkGroup:(OBABookmarkGroup*)bookmarkGroup;
- (void)persistGroups;

- (OBAStopPreferencesV2*)stopPreferencesForStopWithId:(NSString*)stopId;
- (void)setStopPreferences:(OBAStopPreferencesV2*)preferences forStopWithId:(NSString*)stopId;

- (BOOL) isVisitedSituationWithId:(NSString*)situationId;
- (void) setVisited:(BOOL)visited forSituationWithId:(NSString*)situationId;

- (OBAServiceAlertsModel*) getServiceAlertsModelForSituations:(NSArray*)situations;

// Recent Stops

- (void)clearMostRecentStops;
- (void)viewedArrivalsAndDeparturesForStop:(OBAStopV2*)stop;

// Regions

- (NSArray<OBARegionV2*>*)customRegions;
- (void)addCustomRegion:(OBARegionV2*)region;
- (void)removeCustomRegion:(OBARegionV2*)region;

@end

NS_ASSUME_NONNULL_END
