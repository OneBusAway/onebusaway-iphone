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

#import <OBAKit/OBAModelDAO.h>
#import <OBAKit/OBACommon.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBAStopAccessEventV2.h>
#import <OBAKit/OBASituationV2.h>
#import <OBAKit/OBAModelDAOUserPreferencesImpl.h>
#import <OBAKit/OBAPlacemark.h>
#import <OBAKit/OBABookmarkGroup.h>
#import <OBAKit/OBAApplication.h>
#import <OBAKit/NSArray+OBAAdditions.h>
#import <OBAKit/OBALogging.h>
#import <OBAKit/OBAMapHelpers.h>

NSString * const OBAUngroupedBookmarksIdentifier = @"OBAUngroupedBookmarksIdentifier";
NSString * const OBAMostRecentStopsChangedNotification = @"OBAMostRecentStopsChangedNotification";
NSString * const OBARegionDidUpdateNotification = @"OBARegionDidUpdateNotification";

const NSInteger kMaxEntriesInMostRecentList = 10;
const CLLocationDistance kMetersInOneMile = 1609.34;

@interface OBAModelDAO ()
@property(nonatomic,strong) id<OBAModelPersistenceLayer> preferencesDao;
@property(nonatomic,strong,readwrite) NSMutableArray<OBABookmarkV2*> *bookmarks;
@property(nonatomic,strong,readwrite) NSMutableArray<OBABookmarkGroup*> *bookmarkGroups;
@property(nonatomic,strong,readwrite) NSMutableArray *mostRecentStops;
@property(nonatomic,strong,readwrite) NSMutableDictionary *stopPreferences;
@property(nonatomic,strong) NSMutableSet *visitedSituationIds;
@end

@implementation OBAModelDAO
@dynamic hideFutureLocationWarnings;
@dynamic ungroupedBookmarksOpen;
@dynamic automaticallySelectRegion;

// i feel like i must be missing something dumb. this shouldn't be required.
@synthesize currentRegion = _currentRegion;

- (instancetype)initWithModelPersistenceLayer:(id<OBAModelPersistenceLayer>)persistenceLayer {
    self = [super init];

    if (self) {
        _preferencesDao = persistenceLayer;
        _bookmarks = [[NSMutableArray alloc] initWithArray:[_preferencesDao readBookmarks]];

        NSArray<OBABookmarkGroup*> *groups = [_preferencesDao readBookmarkGroups];
        if (![groups isKindOfClass:NSArray.class] || ![self.class bookmarkGroupsContainTodayGroup:groups]) {
            groups = [self.class bookmarkGroupsWithPreprendedTodayGroup:groups];
        }

        _bookmarkGroups = [[NSMutableArray alloc] initWithArray:groups];
        _mostRecentStops = [[NSMutableArray alloc] initWithArray:[_preferencesDao readMostRecentStops]];
        _stopPreferences = [[NSMutableDictionary alloc] initWithDictionary:[_preferencesDao readStopPreferences]];
        _mostRecentLocation = [_preferencesDao readMostRecentLocation];
        _visitedSituationIds = [[NSMutableSet alloc] initWithSet:[_preferencesDao readVisistedSituationIds]];
    }

    return self;
}

#pragma mark - Recent

- (void)setMostRecentLocation:(CLLocation*)location {
    _mostRecentLocation = [location copy];
    [_preferencesDao writeMostRecentLocation:_mostRecentLocation];
}

#pragma mark - Regions

- (void)setCurrentRegion:(OBARegionV2 *)currentRegion {
    if ([_currentRegion isEqual:currentRegion]) {
        return;
    }

    _currentRegion = currentRegion;
    [_preferencesDao writeOBARegion:currentRegion];

    [[NSNotificationCenter defaultCenter] postNotificationName:OBARegionDidUpdateNotification object:nil];
}

- (OBARegionV2*)currentRegion {
    if (!_currentRegion) {
        _currentRegion = [_preferencesDao readOBARegion];
    }
    return _currentRegion;
}

- (BOOL)automaticallySelectRegion {
    return [_preferencesDao readSetRegionAutomatically];
}

- (void)setAutomaticallySelectRegion:(BOOL)automaticallySelectRegion {
    [_preferencesDao writeSetRegionAutomatically:automaticallySelectRegion];
}

- (NSArray*)customRegions {
    NSSet *regions = [_preferencesDao customRegions];
    NSArray *sortedRegions = [regions.allObjects sortedArrayUsingSelector:@selector(compare:)];
    return sortedRegions;
}

- (void)addCustomRegion:(OBARegionV2*)region {
    [_preferencesDao addCustomRegion:region];
}

- (void)removeCustomRegion:(OBARegionV2*)region {
    [_preferencesDao removeCustomRegion:region];
}

#pragma mark - Bookmarks

- (NSArray<OBABookmarkV2*>*)bookmarksMatchingPredicate:(NSPredicate*)predicate {
    OBAGuard(predicate) else {
        return @[];
    }

    NSArray<OBABookmarkV2*> *allBookmarks = [self allBookmarks];

    return [allBookmarks filteredArrayUsingPredicate:predicate];
}

- (NSArray<OBABookmarkV2*>*)mappableBookmarksMatchingString:(NSString*)matching {
    OBAGuard(matching) else {
        return @[];
    }

    NSPredicate *namePredicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", @"name", matching];
    NSPredicate *routePredicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", @"routeShortName", matching];
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[namePredicate, routePredicate]];

    return [self.mappableBookmarksForCurrentRegion filteredArrayUsingPredicate:compoundPredicate];
}

- (OBABookmarkV2*)bookmarkForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrival {
    for (OBABookmarkV2 *bm in self.ungroupedBookmarks) {
        if ([bm matchesArrivalAndDeparture:arrival]) {
            return bm;
        }
    }

    for (OBABookmarkGroup *group in self.bookmarkGroups) {
        for (OBABookmarkV2 *bm in group.bookmarks) {
            if ([bm matchesArrivalAndDeparture:arrival]) {
                return bm;
            }
        }
    }

    return nil;
}

- (NSArray*)ungroupedBookmarks {
    return _bookmarks;
}

- (NSUInteger)allBookmarksCount {
    return [self allBookmarks].count;
}

- (NSArray*)allBookmarks {
    NSMutableArray *all = [[NSMutableArray alloc] initWithArray:self.ungroupedBookmarks];
    for (OBABookmarkGroup *group in self.bookmarkGroups) {
        [all addObjectsFromArray:group.bookmarks];
    }
    return [NSArray arrayWithArray:all];
}

- (NSArray*)bookmarksForCurrentRegion {
    if (!self.currentRegion) {
        return @[];
    }

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", NSStringFromSelector(@selector(regionIdentifier)), @[@(self.currentRegion.identifier)]];
    return [self.allBookmarks filteredArrayUsingPredicate:predicate];
}

- (NSArray<OBABookmarkV2*>*)mappableBookmarksForCurrentRegion {
    NSArray *bookmarks = self.bookmarksForCurrentRegion;

    NSArray *filtered = [bookmarks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OBABookmarkV2* bookmark, NSDictionary *bindings) {
        return bookmark.stopId && CLLocationCoordinate2DIsValid(bookmark.coordinate) && bookmark.coordinate.latitude != 0 && bookmark.coordinate.longitude != 0;
    }]];

    return filtered;
}

- (NSArray *)bookmarkGroups {
    return _bookmarkGroups;
}

- (void)saveBookmark:(OBABookmarkV2*)bookmark {
    if (bookmark.group) {
        [self saveBookmarkGroup:bookmark.group];
    }
    else {
        if (![_bookmarks containsObject:bookmark]) {
            [_bookmarks addObject:bookmark];
        }

        [_preferencesDao writeBookmarks:_bookmarks];
    }
}

- (void)moveBookmark:(NSUInteger)startIndex to:(NSUInteger)endIndex {
    if (startIndex == endIndex) {
        return;
    }

    if (startIndex >= _bookmarks.count) {
        return;
    }

    @synchronized(self) {
        NSUInteger bookmarksCount = _bookmarks.count;

        OBABookmarkV2 * bm = _bookmarks[startIndex];
        [_bookmarks removeObjectAtIndex:startIndex];

        // If the caller put this bookmark out of bounds, then
        // just stick the bookmark at the end of the array and
        // call it a day.
        endIndex = MIN(endIndex, bookmarksCount - 1);
        [_bookmarks insertObject:bm atIndex:endIndex];
        [_preferencesDao writeBookmarks:_bookmarks];
    }
}

- (void)removeBookmark:(OBABookmarkV2*)bookmark {
    if (bookmark.group) {
        OBABookmarkGroup *group = bookmark.group;

        [group removeBookmark:bookmark];

        // The group is empty. Delete it.
        if (group.bookmarks.count == 0 && group.bookmarkGroupType != OBABookmarkGroupTypeTodayWidget) {
            [_bookmarkGroups removeObject:group];
        }

        [self persistGroups];
    }
    else {
        [_bookmarks removeObject:bookmark];
        [_preferencesDao writeBookmarks:_bookmarks];
    }
}

- (void)persistGroups {
    [_preferencesDao writeBookmarkGroups:_bookmarkGroups];
}

#pragma mark - Bookmarks in Groups

- (nullable OBABookmarkV2*)bookmarkAtIndex:(NSUInteger)index inGroup:(nullable OBABookmarkGroup*)group {
    NSArray *bookmarks = group ? group.bookmarks : self.ungroupedBookmarks;

    OBAGuard(bookmarks.count > index) else {
        return nil;
    }

    return bookmarks[index];
}

- (void)moveBookmark:(OBABookmarkV2*)bookmark toGroup:(nullable OBABookmarkGroup*)group {
    if (!group) {
        if (![_bookmarks containsObject:bookmark]) {
            [_bookmarks addObject:bookmark];
        }
        [bookmark.group removeBookmark:bookmark];
    }
    else if (bookmark.group) {
        [bookmark.group removeBookmark:bookmark];
        [group addBookmark:bookmark];
    }
    else {
        [_bookmarks removeObject:bookmark];
        [group addBookmark:bookmark];
    }
    bookmark.group = group;
    [_preferencesDao writeBookmarks:_bookmarks];
    [self persistGroups];
}

- (void)moveBookmark:(NSUInteger)startIndex to:(NSUInteger)endIndex inGroup:(OBABookmarkGroup*)group {
    if (startIndex == endIndex) {
        return;
    }

    NSUInteger bookmarksCount = group.bookmarks.count;

    if (startIndex >= bookmarksCount) {
        return;
    }

    @synchronized (self) {
        OBABookmarkV2 *bm = group.bookmarks[startIndex];
        [group removeBookmark:bm];

        // If the caller put this bookmark out of bounds, then
        // just stick the bookmark at the end of the array and
        // call it a day.
        [group insertBookmark:bm atIndex:MIN(endIndex, bookmarksCount - 1)];
        [self persistGroups];
    }
}

- (void)moveBookmark:(OBABookmarkV2*)bookmark toIndex:(NSUInteger)index inGroup:(nullable OBABookmarkGroup*)group {
    OBAGuard(bookmark) else {
        return;
    }

    [self moveBookmark:bookmark toGroup:group];

    if (group) {
        NSUInteger idx = [group.bookmarks indexOfObject:bookmark];
        [self moveBookmark:idx to:index inGroup:group];
    }
    else {
        NSUInteger idx = [self.ungroupedBookmarks indexOfObject:bookmark];
        [self moveBookmark:idx to:index];
    }
}

#pragma mark - Bookmark Groups

- (NSArray<OBABookmarkGroup*>*)userCreatedBookmarkGroups {
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K != %@", NSStringFromSelector(@selector(bookmarkGroupType)), @(OBABookmarkGroupTypeTodayWidget)];
    return [self.bookmarkGroups filteredArrayUsingPredicate:filter];
}

- (OBABookmarkGroup*)todayBookmarkGroup {
    for (OBABookmarkGroup *group in self.bookmarkGroups) {
        if (group.bookmarkGroupType == OBABookmarkGroupTypeTodayWidget) {
            return group;
        }
    }

    // This should never happen, but I want to make sure
    // something sensible happens if it does.
    OBAGuard(NO) else {
        return [[OBABookmarkGroup alloc] initWithBookmarkGroupType:OBABookmarkGroupTypeTodayWidget];
    }
}

- (void)moveBookmarkGroup:(OBABookmarkGroup*)bookmarkGroup toIndex:(NSUInteger)index {
    OBAGuard(bookmarkGroup) else {
        return;
    }

    NSUInteger currentIndex = [_bookmarkGroups indexOfObject:bookmarkGroup];

    if (currentIndex == index) {
        // no-op.
        return;
    }

    // check to see if the index is out of bounds for groups array.
    // If it is out of bounds, reset the target index to be the end
    // of the array.
    if (index >= _bookmarkGroups.count) {
        index = _bookmarkGroups.count - 1;
    }

    // remove the group from the array.
    [_bookmarkGroups removeObject:bookmarkGroup];

    // reinsert the group at the specified index.
    [_bookmarkGroups insertObject:bookmarkGroup atIndex:index];

    // rewrite sort orders to ensure values increase monotonically
    [self rewriteBookmarkGroupSortOrderToIncreaseMonotonically];

    [self persistGroups];
}

- (void)saveBookmarkGroup:(OBABookmarkGroup *)bookmarkGroup {

    // Add the bookmark group to the list if it doesn't yet exist.
    if (![_bookmarkGroups containsObject:bookmarkGroup]) {
        bookmarkGroup.sortOrder = self.bookmarkGroups.count;
        [_bookmarkGroups addObject:bookmarkGroup];
    }

    // Sort the bookmark groups by sort order.
    [_bookmarkGroups sortUsingSelector:@selector(compare:)];

    // Rewrite their sort orders to ensure that
    // the values increase monotonically.
    [self rewriteBookmarkGroupSortOrderToIncreaseMonotonically];

    [self persistGroups];
}

- (void)removeBookmarkGroup:(OBABookmarkGroup *)bookmarkGroup {
    for (OBABookmarkV2 *bm in bookmarkGroup.bookmarks) {
        [_bookmarks addObject:bm];
        bm.group = nil;
    }
    [_bookmarkGroups removeObject:bookmarkGroup];
    [_preferencesDao writeBookmarks:_bookmarks];
    [self persistGroups];
}

- (void)rewriteBookmarkGroupSortOrderToIncreaseMonotonically {
    for (NSUInteger i=0;i<_bookmarkGroups.count;i++) {
        _bookmarkGroups[i].sortOrder = i;
    }
}

+ (BOOL)bookmarkGroupsContainTodayGroup:(NSArray<OBABookmarkGroup*>*)groups {
    for (OBABookmarkGroup *g in groups) {
        if (g.bookmarkGroupType == OBABookmarkGroupTypeTodayWidget) {
            return YES;
        }
    }
    return NO;
}

+ (NSArray*)bookmarkGroupsWithPreprendedTodayGroup:(NSArray<OBABookmarkGroup*>*)groups {
    OBABookmarkGroup *todayGroup = [[OBABookmarkGroup alloc] initWithBookmarkGroupType:OBABookmarkGroupTypeTodayWidget];
    todayGroup.sortOrder = 0;

    if (![groups isKindOfClass:NSArray.class]) {
        return @[todayGroup];
    }

    @try {
        NSMutableArray *sortedGroups = [[NSMutableArray alloc] initWithArray:groups];

        for (OBABookmarkGroup *g in sortedGroups) {
            g.sortOrder += 1;
        }

        [sortedGroups insertObject:todayGroup atIndex:0];

        return [NSArray arrayWithArray:sortedGroups];
    }
    @catch (NSException *ex) {
        DDLogError(@"Caught an exception while trying to load bookmark groups: %@", ex);
        return @[todayGroup];
    }
}

#pragma mark - Misc

- (void)setUngroupedBookmarksOpen:(BOOL)open {
    self.preferencesDao.ungroupedBookmarksOpen = open;
}

- (BOOL)ungroupedBookmarksOpen {
    return self.preferencesDao.ungroupedBookmarksOpen;
}

#pragma mark - Stop Preferences

- (OBAStopPreferencesV2*) stopPreferencesForStopWithId:(NSString*)stopId {
    OBAStopPreferencesV2 * prefs = _stopPreferences[stopId];

    if (!prefs) {
        return [[OBAStopPreferencesV2 alloc] init];
    }

    return [[OBAStopPreferencesV2 alloc] initWithStopPreferences:prefs];
}

- (void)setStopPreferences:(OBAStopPreferencesV2*)preferences forStopWithId:(NSString*)stopId {
    OBAGuard(stopId.length > 0) else {
        return;
    }

    _stopPreferences[stopId] = preferences;
    [_preferencesDao writeStopPreferences:_stopPreferences];
}

#pragma mark - Location Warnings

- (BOOL) hideFutureLocationWarnings {
    return [_preferencesDao hideFutureLocationWarnings];
}

- (void) setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings {
    [_preferencesDao setHideFutureLocationWarnings:hideFutureLocationWarnings];
}

#pragma mark - Recent Stops

- (void)clearMostRecentStops {
    [_mostRecentStops removeAllObjects];
    [_preferencesDao writeMostRecentStops:_mostRecentStops];
    [[NSNotificationCenter defaultCenter] postNotificationName:OBAMostRecentStopsChangedNotification object:nil];
}

- (void)viewedArrivalsAndDeparturesForStop:(OBAStopV2*)stop {
    OBAGuard(stop) else {
        return;
    }

    for (OBAStopAccessEventV2 *stopEvent in _mostRecentStops) {
        if ([stopEvent.stopID isEqual:stop.stopId]) {
            [_mostRecentStops removeObject:stopEvent];
            break;
        }
    }

    OBAStopAccessEventV2 *recentStop = [[OBAStopAccessEventV2 alloc] initWithStop:stop];
    [_mostRecentStops insertObject:recentStop atIndex:0];

    NSInteger over = self.mostRecentStops.count - kMaxEntriesInMostRecentList;
    for (NSInteger i=0; i<over; i++) {
        [_mostRecentStops removeObjectAtIndex:_mostRecentStops.count - 1];
    }

    [_preferencesDao writeMostRecentStops:_mostRecentStops];
    [[NSNotificationCenter defaultCenter] postNotificationName:OBAMostRecentStopsChangedNotification object:nil];
}

- (void)removeRecentStop:(OBAStopAccessEventV2*)recentStop {
    [_mostRecentStops removeObject:recentStop];
    [_preferencesDao writeMostRecentStops:_mostRecentStops];
    [[NSNotificationCenter defaultCenter] postNotificationName:OBAMostRecentStopsChangedNotification object:nil];
}

- (NSArray<OBAStopAccessEventV2*>*)recentStopsMatchingString:(NSString*)matching {
    OBAGuard(matching) else {
        return @[];
    }

    NSPredicate *titlePredicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", @"title", matching];
    NSPredicate *subtitlePredicate = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", @"subtitle", matching];
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[titlePredicate, subtitlePredicate]];

    NSArray *rows = [self.mostRecentStops filteredArrayUsingPredicate:compoundPredicate];
    return rows;
}

- (NSArray<OBAStopAccessEventV2*>*)recentStopsNearCoordinate:(CLLocationCoordinate2D)coordinate {
    OBAGuard(CLLocationCoordinate2DIsValid(coordinate)) else {
        return @[];
    }

    NSArray<OBAStopAccessEventV2*> *recentStopsWithinOneMile = [self.mostRecentStops filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OBAStopAccessEventV2 *evaluatedObject, NSDictionary<NSString *,id> *bindings) {
        if (!evaluatedObject.hasLocation) {
            return NO;
        }

        return [OBAMapHelpers getDistanceFrom:evaluatedObject.coordinate to:coordinate] < kMetersInOneMile;
    }]];

    NSArray<OBAStopAccessEventV2*> *sortedRecentStops = [recentStopsWithinOneMile sortedArrayUsingComparator:^NSComparisonResult(OBAStopAccessEventV2 *obj1, OBAStopAccessEventV2 *obj2) {
        CLLocationDistance dist1 = [OBAMapHelpers getDistanceFrom:obj1.coordinate to:coordinate];
        CLLocationDistance dist2 = [OBAMapHelpers getDistanceFrom:obj2.coordinate to:coordinate];

        if (dist1 < dist2) {
            return NSOrderedAscending;
        }
        else if (dist1 > dist2) {
            return NSOrderedDescending;
        }
        else {
            return NSOrderedSame;
        }
    }];

    return sortedRecentStops;
}

#pragma mark - Service Alerts

- (BOOL)isVisitedSituationWithId:(NSString*)situationId {
    return [self.visitedSituationIds containsObject:situationId];
}

- (OBAServiceAlertsModel*)getServiceAlertsModelForSituations:(NSArray*)situations {

    OBAServiceAlertsModel * model = [[OBAServiceAlertsModel alloc] init];

    model.totalCount = [situations count];
    
    NSInteger maxUnreadSeverityValue = -99;
    NSInteger maxSeverityValue = -99;
    
    for (OBASituationV2 * situation in situations) {
        NSString * severity = situation.severity;
        NSInteger severityValue = [situation severityAsNumericValue];

        if (![self isVisitedSituationWithId:situation.situationId]) {
            model.unreadCount += 1;
            
            if (!model.unreadMaxSeverity || severityValue > maxUnreadSeverityValue) {
                model.unreadMaxSeverity = severity;
                maxUnreadSeverityValue = severityValue;
            }
        }
        
        if (!model.maxSeverity || severityValue > maxSeverityValue) {
            model.maxSeverity = severity;
            maxSeverityValue = severityValue;
        }
    }    
    
    return model;
}

- (void)setVisited:(BOOL)visited forSituationWithId:(NSString*)situationId {

    if ([_visitedSituationIds containsObject:situationId]) {
        return;
    }

    if (visited) {
        [_visitedSituationIds addObject:situationId];
    }
    else {
        [_visitedSituationIds removeObject:situationId];
    }

    [_preferencesDao writeVisistedSituationIds:_visitedSituationIds];
}

#pragma mark - PII/Privacy

- (void)setShareRegionPII:(BOOL)shareRegionPII {
    [_preferencesDao setShareRegionPII:shareRegionPII];
}

- (BOOL)shareRegionPII {
    return [_preferencesDao shareRegionPII];
}

- (void)setShareLocationPII:(BOOL)shareLocationPII {
    [_preferencesDao setShareLocationPII:shareLocationPII];
}

- (BOOL)shareLocationPII {
    return [_preferencesDao shareLocationPII];
}

- (void)setShareLogsPII:(BOOL)shareLogsPII {
    [_preferencesDao setShareLogsPII:shareLogsPII];
}

- (BOOL)shareLogsPII {
    return [_preferencesDao shareLogsPII];
}

#pragma mark - Shared Trips

- (NSArray<OBATripDeepLink*>*)sharedTrips {
    return [[_preferencesDao sharedTrips].allObjects sortedArrayUsingSelector:@selector(compare:)];
}

- (void)addSharedTrip:(OBATripDeepLink*)sharedTrip {
    [_preferencesDao addSharedTrip:sharedTrip];
}

- (void)removeSharedTrip:(OBATripDeepLink*)sharedTrip {
    [_preferencesDao removeSharedTrip:sharedTrip];
}

- (void)clearSharedTrips {
    NSArray<OBATripDeepLink*> *sharedTrips = self.sharedTrips;
    for (OBATripDeepLink *link in sharedTrips) {
        [self removeSharedTrip:link];
    }
}

- (void)clearSharedTripsOlderThan24Hours {
    NSMutableArray *toPurge = [NSMutableArray new];
    NSDate *purgeDate = [NSDate dateWithTimeIntervalSinceNow:-86400.0]; // 86,400 seconds in a day.

    for (OBATripDeepLink *link in self.sharedTrips) {
        if ([link.createdAt timeIntervalSinceDate:purgeDate] < 0) {
            [toPurge addObject:link];
        }
    }

    for (OBATripDeepLink *link in toPurge) {
        [self removeSharedTrip:link];
    }
}

#pragma mark - Alarms

- (NSArray<OBAAlarm*>*)alarms {
    return self.preferencesDao.alarms;
}

- (OBAAlarm*)alarmForKey:(NSString*)alarmKey {
    return [self.preferencesDao alarmForKey:alarmKey];
}

- (void)addAlarm:(OBAAlarm*)alarm {
    [self.preferencesDao addAlarm:alarm];
}

- (void)removeAlarmWithKey:(NSString*)alarmKey {
    [self.preferencesDao removeAlarmWithKey:alarmKey];
}

- (void)clearExpiredAlarms {
    NSArray<OBAAlarm*> *alarms = [[NSArray alloc] initWithArray:self.alarms copyItems:YES];
    NSDate *now = [NSDate date];

    for (OBAAlarm *alarm in alarms) {
        if (alarm.scheduledDeparture.timeIntervalSinceReferenceDate < now.timeIntervalSinceReferenceDate) {
            [self removeAlarmWithKey:alarm.alarmKey];
        }
    }
}

@end

