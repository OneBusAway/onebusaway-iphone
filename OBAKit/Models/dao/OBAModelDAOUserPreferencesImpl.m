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

#import <OBAKit/OBAModelDAOUserPreferencesImpl.h>
@import CoreLocation;
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBARegionV2.h>
#import <OBAKit/OBALogging.h>
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBAAlarm.h>
#import <OBAKit/OBAApplication.h>

NSString * const kBookmarksKey = @"bookmarks";
NSString * const kBookmarkGroupsKey = @"bookmarkGroups";
NSString * const kMostRecentStopsKey = @"mostRecentStops";
NSString * const kStopPreferencesKey = @"stopPreferences";
NSString * const kMostRecentLocationKey = @"mostRecentLocation";
NSString * const kHideFutureLocationWarningsKey = @"hideFutureLocationWarnings";
NSString * const kVisitedSituationIdsKey = @"visitedSituationIdsKey";
NSString * const kOBARegionKey = @"oBARegion";
NSString * const kCustomRegionsKey = @"customRegions";
NSString * const kSharedTripsKey = @"sharedTrips";
NSString * const kAlarmsKey = @"AlarmsKey";
NSString * const OBASetRegionAutomaticallyKey = @"OBASetRegionAutomaticallyUserDefaultsKey";
NSString * const kUngroupedBookmarksOpenKey = @"UngroupedBookmarksOpen";
NSString * const OBAShareRegionPIIUserDefaultsKey = @"OBAShareRegionPIIUserDefaultsKey";
NSString * const OBAShareLocationPIIUserDefaultsKey = @"OBAShareLocationPIIUserDefaultsKey";
NSString * const OBAShareLogsPIIUserDefaultsKey = @"OBAShareLogsPIIUserDefaultsKey";
NSString * const OBAUseStopDrawerDefaultsKey = @"OBAUseStopDrawerDefaultsKey2";

@implementation OBAModelDAOUserPreferencesImpl
@dynamic shareRegionPII;
@dynamic shareLocationPII;
@dynamic shareLogsPII;

- (void)setUngroupedBookmarksOpen:(BOOL)ungroupedBookmarksOpen {
    [self.userDefaults setBool:ungroupedBookmarksOpen forKey:kUngroupedBookmarksOpenKey];
}

- (BOOL)ungroupedBookmarksOpen {
    return [self.userDefaults boolForKey:kUngroupedBookmarksOpenKey];
}

- (NSArray*)readBookmarks {
    return [self.class loadAndDecodeObjectFromDataForKey:kBookmarksKey] ?: @[];
}

- (void)writeBookmarks:(NSArray*)source {
    [self.class writeObjectToUserDefaults:source withKey:kBookmarksKey];
}

- (NSArray*)readBookmarkGroups {
    return [self.class loadAndDecodeObjectFromDataForKey:kBookmarkGroupsKey] ?: @[];
}

- (void)writeBookmarkGroups:(NSArray*)source {
    [self.class writeObjectToUserDefaults:source withKey:kBookmarkGroupsKey];
}

- (NSArray*)readMostRecentStops {
    return [self.class loadAndDecodeObjectFromDataForKey:kMostRecentStopsKey] ?: @[];
}

- (void)writeMostRecentStops:(NSArray*)source {
    [self.class writeObjectToUserDefaults:source withKey:kMostRecentStopsKey];
}

- (NSDictionary*)readStopPreferences {
    id out = [self.class loadAndDecodeObjectFromDataForKey:kStopPreferencesKey] ?: @{};
    return out;
}

- (void)writeStopPreferences:(NSDictionary*)stopPreferences {
    [self.class writeObjectToUserDefaults:stopPreferences withKey:kStopPreferencesKey];
}

- (CLLocation*)readMostRecentLocation {
    return [self.class loadAndDecodeObjectFromDataForKey:kMostRecentLocationKey];
}

- (void)writeMostRecentLocation:(CLLocation*)mostRecentLocation {
    [self.class writeObjectToUserDefaults:mostRecentLocation withKey:kMostRecentLocationKey];
}

- (BOOL)hideFutureLocationWarnings {
    return [self.userDefaults boolForKey:kHideFutureLocationWarningsKey];
}

- (void)setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings {
    [self.userDefaults setBool:hideFutureLocationWarnings forKey:kHideFutureLocationWarningsKey];
}

- (NSSet*)readVisistedSituationIds {
    return [self.class loadAndDecodeObjectFromDataForKey:kVisitedSituationIdsKey] ?: [NSSet set];
}

- (void)writeVisistedSituationIds:(NSSet*)situationIds {
    [self.class writeObjectToUserDefaults:situationIds withKey:kVisitedSituationIdsKey];
}

#pragma mark - Regions

- (OBARegionV2*)readOBARegion {
    return [self.class loadAndDecodeObjectFromDataForKey:kOBARegionKey];
}

- (void)writeOBARegion:(OBARegionV2 *)region {
    [self.class writeObjectToUserDefaults:region withKey:kOBARegionKey];
}

- (NSSet<OBARegionV2*>*)customRegions {
    @synchronized (self) {
        return [self.class loadAndDecodeObjectFromDataForKey:kCustomRegionsKey] ?: [NSSet set];
    }
}

- (void)addCustomRegion:(OBARegionV2*)region {
    [self addObject:region toSetWithKey:kCustomRegionsKey];
}

- (void)removeCustomRegion:(OBARegionV2*)region {
    [self removeObject:region fromSetWithKey:kCustomRegionsKey];
}

- (BOOL)readSetRegionAutomatically {
    return [self.userDefaults boolForKey:OBASetRegionAutomaticallyKey];
}

- (void)writeSetRegionAutomatically:(BOOL)setRegionAutomatically {
    [self.userDefaults setBool:setRegionAutomatically forKey:OBASetRegionAutomaticallyKey];
}

#pragma mark - Privacy/PII

- (BOOL)shareRegionPII {
    return [self.userDefaults boolForKey:OBAShareRegionPIIUserDefaultsKey];
}

- (void)setShareRegionPII:(BOOL)shareRegionPII {
    [self.userDefaults setBool:shareRegionPII forKey:OBAShareRegionPIIUserDefaultsKey];
}

- (BOOL)shareLocationPII {
    return [self.userDefaults boolForKey:OBAShareLocationPIIUserDefaultsKey];
}

- (void)setShareLocationPII:(BOOL)shareLocationPII {
    [self.userDefaults setBool:shareLocationPII forKey:OBAShareLocationPIIUserDefaultsKey];
}

- (BOOL)shareLogsPII {
    return [self.userDefaults boolForKey:OBAShareLogsPIIUserDefaultsKey];
}

- (void)setShareLogsPII:(BOOL)shareLogsPII {
    [self.userDefaults setBool:shareLogsPII forKey:OBAShareLogsPIIUserDefaultsKey];
}

#pragma mark - Shared Trips

- (NSSet<OBATripDeepLink*>*)sharedTrips {
    @synchronized (self) {
        return [self.class loadAndDecodeObjectFromDataForKey:kSharedTripsKey] ?: [NSSet set];
    }
}

- (void)addSharedTrip:(OBATripDeepLink*)sharedTrip {
    [self addObject:sharedTrip toSetWithKey:kSharedTripsKey];
}

- (void)removeSharedTrip:(OBATripDeepLink*)sharedTrip {
    [self removeObject:sharedTrip fromSetWithKey:kSharedTripsKey];
}

#pragma mark - Alarms

- (NSArray<OBAAlarm*>*)alarms {
    @synchronized (kAlarmsKey) {
        NSDictionary *alarms = [self.class loadAndDecodeObjectFromDataForKey:kAlarmsKey];
        return alarms.count > 0 ? alarms.allValues : @[];
    }
}

- (OBAAlarm*)alarmForKey:(NSString*)alarmKey {
    @synchronized (kAlarmsKey) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[self.class loadAndDecodeObjectFromDataForKey:kAlarmsKey] ?: [NSDictionary dictionary]];
        return dict[alarmKey];
    }
}

- (void)addAlarm:(OBAAlarm*)alarm {
    @synchronized (kAlarmsKey) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[self.class loadAndDecodeObjectFromDataForKey:kAlarmsKey] ?: [NSDictionary dictionary]];
        dict[alarm.alarmKey] = alarm;
        [self.class writeObjectToUserDefaults:dict withKey:kAlarmsKey];
    }
}

- (void)removeAlarmWithKey:(NSString*)alarmKey {
    @synchronized (kAlarmsKey) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[self.class loadAndDecodeObjectFromDataForKey:kAlarmsKey] ?: [NSDictionary dictionary]];
        [dict removeObjectForKey:alarmKey];
        [self.class writeObjectToUserDefaults:dict withKey:kAlarmsKey];
    }
}

#pragma mark - User Defaults

+ (NSUserDefaults*)userDefaults {
    return OBAApplication.sharedApplication.userDefaults;
}

- (NSUserDefaults*)userDefaults {
    return [self.class userDefaults];
}

#pragma mark - Generic Set Management Methods

- (void)addObject:(id)object toSetWithKey:(NSString*)key {
    OBAGuard(object && key.length > 0) else {
        return;
    }

    @synchronized (self) {
        NSSet *set = [self.class loadAndDecodeObjectFromDataForKey:key] ?: [NSSet set];
        NSMutableSet *mutableSet = [NSMutableSet setWithSet:set];
        [mutableSet addObject:object];
        [self.class writeObjectToUserDefaults:mutableSet withKey:key];
    }
}

- (void)removeObject:(id)object fromSetWithKey:(NSString*)key {
    OBAGuard(object && key.length > 0) else {
        return;
    }

    @synchronized (self) {
        NSSet *set = [self.class loadAndDecodeObjectFromDataForKey:key] ?: [NSSet set];
        NSMutableSet *mutableSet = [NSMutableSet setWithSet:set];
        [mutableSet removeObject:object];
        [self.class writeObjectToUserDefaults:mutableSet withKey:key];
    }
}

#pragma mark - (De-)Serialization

+ (id)loadAndDecodeObjectFromDataForKey:(NSString*)key {
    NSData *data = [self.userDefaults dataForKey:key];

    if (!data) {
        return nil;
    }

    id object = nil;

    @try {
        NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        object = [unarchiver decodeObjectForKey:key];
        [unarchiver finishDecoding];
    }
    @catch (NSException *exception) {
        DDLogError(@"Unable to decode object for key %@ - %@", key, exception);
    }

    return object;
}

+ (void)writeObjectToUserDefaults:(id<NSCoding>)object withKey:(NSString*)key {
    NSMutableData * data = [NSMutableData data];

    NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:object forKey:key];
    [archiver finishEncoding];

    [self.userDefaults setObject:data forKey:key];
}
@end
