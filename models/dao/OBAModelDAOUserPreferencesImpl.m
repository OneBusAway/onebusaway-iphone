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


static NSString * kBookmarksKey = @"bookmarks";
static NSString * kBookmarkGroupsKey = @"bookmarkGroups";
static NSString * kMostRecentStopsKey = @"mostRecentStops";
static NSString * kStopPreferencesKey = @"stopPreferences";
static NSString * kMostRecentLocationKey = @"mostRecentLocation";
static NSString * kHideFutureLocationWarningsKey = @"hideFutureLocationWarnings";
static NSString * kVisitedSituationIdsKey = @"hideFutureLocationWarnings";
static NSString * kOBARegionKey = @"oBARegion";
static NSString * kSetRegionAutomaticallyKey = @"setRegionAutomatically";
static NSString * kCustomApiUrlKey = @"customApiUrl";
static NSString * kMostRecentCustomApiUrlsKey = @"mostRecentCustomApiUrls";


@interface OBAModelDAOUserPreferencesImpl ()

- (void) encodeObject:(id<NSCoding>)object forKey:(NSString*)key toData:(NSMutableData*)data;
- (id) decodeObjectForKey:(NSString*)key fromData:(NSData*)data;

@end


@implementation OBAModelDAOUserPreferencesImpl

- (NSArray*) readBookmarks {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSData * data = [user dataForKey:kBookmarksKey];
    NSArray * bookmarks = nil;
    @try {
        bookmarks = [self decodeObjectForKey:kBookmarksKey fromData:data];
    }
    @catch (NSException * e) {
        
    }
    
    if( ! bookmarks )
        bookmarks = [[NSArray alloc] init];
    
    return bookmarks;
}

- (void) writeBookmarks:(NSArray*)source {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSMutableData * data = [NSMutableData data];
    [self encodeObject:source forKey:kBookmarksKey toData:data];
    [user setObject:data forKey:kBookmarksKey];
    [user synchronize];
}

- (NSArray*) readBookmarkGroups {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSData * data = [user dataForKey:kBookmarkGroupsKey];
    NSArray * bookmarkGroups = nil;
    @try {
        bookmarkGroups = [self decodeObjectForKey:kBookmarkGroupsKey fromData:data];
    }
    @catch (NSException * e) {
    }
    if (!bookmarkGroups) {
        bookmarkGroups = [[NSArray alloc] init];
    }
    return bookmarkGroups;
}

- (void) writeBookmarkGroups:(NSArray*)source {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSMutableData * data = [NSMutableData data];
    [self encodeObject:source forKey:kBookmarkGroupsKey toData:data];
    [user setObject:data forKey:kBookmarkGroupsKey];
    [user synchronize];
}

- (NSArray*) readMostRecentStops {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSData * data = [user dataForKey:kMostRecentStopsKey];
    NSArray * stops = nil;
    @try {
        stops = [self decodeObjectForKey:kMostRecentStopsKey fromData:data];
    }
    @catch (NSException * e) {
        
    }
    
    if( ! stops )
        stops = [[NSArray alloc] init];
    
    return stops;
}

- (void) writeMostRecentStops:(NSArray*)source {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSMutableData * data = [NSMutableData data];
    [self encodeObject:source forKey:kMostRecentStopsKey toData:data];
    [user setObject:data forKey:kMostRecentStopsKey];
}

- (NSDictionary*) readStopPreferences {
    NSDictionary * dictionary = nil;
    @try {
        NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
        NSData * data = [user dataForKey:kStopPreferencesKey];
        dictionary = [self decodeObjectForKey:kStopPreferencesKey fromData:data];
    }
    @catch (NSException * e) {
    }
    
    if( ! dictionary )
        dictionary = [[NSDictionary alloc] init];
    
    return dictionary;
}

- (void) writeStopPreferences:(NSDictionary*)stopPreferences {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSMutableData * data = [NSMutableData data];
    [self encodeObject:stopPreferences forKey:kStopPreferencesKey toData:data];
    [user setObject:data forKey:kStopPreferencesKey];
}

- (CLLocation*) readMostRecentLocation {
    CLLocation * location = nil;
    @try {
        NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
        NSData * data = [user dataForKey:kMostRecentLocationKey];
        location = [self decodeObjectForKey:kMostRecentLocationKey fromData:data];
    }
    @catch (NSException * e) {
    }
    
    return location;
}

- (void) writeMostRecentLocation:(CLLocation*)mostRecentLocation {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSMutableData * data = [NSMutableData data];
    [self encodeObject:mostRecentLocation forKey:kMostRecentLocationKey toData:data];
    [user setObject:data forKey:kMostRecentLocationKey];
}

- (BOOL) hideFutureLocationWarnings {
    @try {
        NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
        NSNumber * v = [user objectForKey:kHideFutureLocationWarningsKey];
        if( v )
            return [v boolValue];
    }
    @catch (NSException * e) {
    }
    
    return NO;
}

- (void) setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSNumber * v = @(hideFutureLocationWarnings);
    [user setObject:v forKey:kHideFutureLocationWarningsKey];
}

- (NSSet*) readVisistedSituationIds {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSData * data = [user dataForKey:kVisitedSituationIdsKey];
    NSSet * situationIds = nil;
    @try {
        situationIds = [self decodeObjectForKey:kVisitedSituationIdsKey fromData:data];
    }
    @catch (NSException * e) {
        
    }
    
    if( ! situationIds )
        situationIds = [[NSSet alloc] init];
    
    return situationIds;
}

- (void) writeVisistedSituationIds:(NSSet*)situationIds {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSMutableData * data = [NSMutableData data];
    [self encodeObject:situationIds forKey:kVisitedSituationIdsKey toData:data];
    [user setObject:data forKey:kVisitedSituationIdsKey];
}

- (OBARegionV2*) readOBARegion {
	OBARegionV2* region = nil;
	@try {
		NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
		NSData * data = [user dataForKey:kOBARegionKey];
		region = [self decodeObjectForKey:kOBARegionKey fromData:data];
	}
	@catch (NSException * e) {
	}
	
	return region;
}

- (void) writeOBARegion:(OBARegionV2 *)oBARegion {
	NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
	NSMutableData * data = [NSMutableData data];
	[self encodeObject:oBARegion forKey:kOBARegionKey toData:data];
	[user setObject:data forKey:kOBARegionKey];
}

- (BOOL) readSetRegionAutomatically {
    @try {
        NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
        NSNumber * v = [user objectForKey:kSetRegionAutomaticallyKey];
        if( v )
            return [v boolValue];
    }
    @catch (NSException * e) {
    }
    
    return YES;
}

- (void) writeSetRegionAutomatically:(BOOL)setRegionAutomatically {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSNumber * v = @(setRegionAutomatically);
    [user setObject:v forKey:kSetRegionAutomaticallyKey];
}

- (NSString*) readCustomApiUrl {
    NSString *customApiUrl = nil;
    @try {
        NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
        NSData * data = [user dataForKey:kCustomApiUrlKey];
        customApiUrl = [self decodeObjectForKey:kCustomApiUrlKey fromData:data];
    }
    @catch (NSException * e) {
    }
    
    if( !customApiUrl )
        customApiUrl = @"";
    
    return customApiUrl;
}

- (void) writeCustomApiUrl:(NSString*)customApiUrl {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSMutableData * data = [NSMutableData data];
    [self encodeObject:customApiUrl forKey:kCustomApiUrlKey toData:data];
    [user setObject:data forKey:kCustomApiUrlKey];
}

- (NSArray*) readMostRecentCustomApiUrls {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSData * data = [user dataForKey:kMostRecentCustomApiUrlsKey];
    NSArray * customApiUrls = nil;
    @try {
        customApiUrls = [self decodeObjectForKey:kMostRecentCustomApiUrlsKey fromData:data];
    }
    @catch (NSException * e) {
        
    }
    
    if(!customApiUrls)
        customApiUrls = [[NSArray alloc] init];
    
    return customApiUrls;
}

- (void) writeMostRecentCustomApiUrls:(NSArray*)customApiUrls {
    NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
    NSMutableData * data = [NSMutableData data];
    [self encodeObject:customApiUrls forKey:kMostRecentCustomApiUrlsKey toData:data];
    [user setObject:data forKey:kMostRecentCustomApiUrlsKey];
}

- (void) encodeObject:(id<NSCoding>)object forKey:(NSString*)key toData:(NSMutableData*)data {
    NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:object forKey:key];
    [archiver finishEncoding];
}

- (id) decodeObjectForKey:(NSString*)key fromData:(NSData*)data {
    id object = nil;

    if (data) {
        NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        object = [unarchiver decodeObjectForKey:key];
        [unarchiver finishDecoding];
    }

    return object;
}

@end
