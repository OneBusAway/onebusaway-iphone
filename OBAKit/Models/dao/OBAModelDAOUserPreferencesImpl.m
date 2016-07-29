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

#import "OBAModelDAOUserPreferencesImpl.h"

NSString * const kBookmarksKey = @"bookmarks";
NSString * const kBookmarkGroupsKey = @"bookmarkGroups";
NSString * const kMostRecentStopsKey = @"mostRecentStops";
NSString * const kStopPreferencesKey = @"stopPreferences";
NSString * const kMostRecentLocationKey = @"mostRecentLocation";
NSString * const kHideFutureLocationWarningsKey = @"hideFutureLocationWarnings";
NSString * const kVisitedSituationIdsKey = @"hideFutureLocationWarnings";
NSString * const kOBARegionKey = @"oBARegion";
NSString * const kSetRegionAutomaticallyKey = @"setRegionAutomatically";
NSString * const kCustomApiUrlKey = @"customApiUrl";
NSString * const kMostRecentCustomApiUrlsKey = @"mostRecentCustomApiUrls";
NSString * const kUngroupedBookmarksOpenKey = @"UngroupedBookmarksOpen";

@implementation OBAModelDAOUserPreferencesImpl

- (void)setUngroupedBookmarksOpen:(BOOL)ungroupedBookmarksOpen {
    [[NSUserDefaults standardUserDefaults] setBool:ungroupedBookmarksOpen forKey:kUngroupedBookmarksOpenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)ungroupedBookmarksOpen {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kUngroupedBookmarksOpenKey];
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
    return [[NSUserDefaults standardUserDefaults] boolForKey:kHideFutureLocationWarningsKey];
}

- (void)setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings {
    [[NSUserDefaults standardUserDefaults] setBool:hideFutureLocationWarnings forKey:kHideFutureLocationWarningsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSSet*)readVisistedSituationIds {
    return [self.class loadAndDecodeObjectFromDataForKey:kVisitedSituationIdsKey] ?: [NSSet set];
}

- (void)writeVisistedSituationIds:(NSSet*)situationIds {
    [self.class writeObjectToUserDefaults:situationIds withKey:kVisitedSituationIdsKey];
}

- (OBARegionV2*)readOBARegion {
    return [self.class loadAndDecodeObjectFromDataForKey:kOBARegionKey];
}

- (void)writeOBARegion:(OBARegionV2 *)region {
    [self.class writeObjectToUserDefaults:region withKey:kOBARegionKey];
}

- (BOOL)readSetRegionAutomatically {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kSetRegionAutomaticallyKey];
}

- (void)writeSetRegionAutomatically:(BOOL)setRegionAutomatically {
    [[NSUserDefaults standardUserDefaults] setBool:setRegionAutomatically forKey:kSetRegionAutomaticallyKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// TODO: I think the idea of slinging around an empty string instead of nil here is an
// incredibly bad idea. But, reworking our custom API support is out of scope for the moment.
- (NSString*)readCustomApiUrl {
    return [self.class loadAndDecodeObjectFromDataForKey:kCustomApiUrlKey] ?: @"";
}

- (void)writeCustomApiUrl:(NSString*)customApiUrl {
    [self.class writeObjectToUserDefaults:customApiUrl withKey:kCustomApiUrlKey];
}

- (NSArray*)readMostRecentCustomApiUrls {
    return [self.class loadAndDecodeObjectFromDataForKey:kMostRecentCustomApiUrlsKey] ?: @[];
}

- (void)writeMostRecentCustomApiUrls:(NSArray*)customApiUrls {
    [self.class writeObjectToUserDefaults:customApiUrls withKey:kMostRecentCustomApiUrlsKey];
}

#pragma mark - (De-)Serialization

+ (id)loadAndDecodeObjectFromDataForKey:(NSString*)key {
    NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:key];

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
        NSLog(@"Unable to decode object for key %@ - %@", key, exception);
    }

    return object;
}

+ (void)writeObjectToUserDefaults:(id<NSCoding>)object withKey:(NSString*)key {
    NSMutableData * data = [NSMutableData data];

    NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:object forKey:key];
    [archiver finishEncoding];

    [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
@end
