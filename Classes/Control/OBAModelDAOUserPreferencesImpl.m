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
static NSString * kMostRecentStopsKey = @"mostRecentStops";
static NSString * kStopPreferencesKey = @"stopPreferences";
static NSString * kMostRecentLocationKey = @"mostRecentLocation";
static NSString * kHideFutureLocationWarningsKey = @"hideFutureLocationWarnings";
static NSString * kVisitedSituationIdsKey = @"hideFutureLocationWarnings";


@interface OBAModelDAOUserPreferencesImpl (Private)

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
	
	return FALSE;
}

- (void) setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings {
	NSUserDefaults * user = [NSUserDefaults standardUserDefaults];
	NSNumber * v = [NSNumber numberWithBool:hideFutureLocationWarnings];
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



@end


@implementation OBAModelDAOUserPreferencesImpl (Private)

- (void) encodeObject:(id<NSCoding>)object forKey:(NSString*)key toData:(NSMutableData*)data {
	NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
	[archiver encodeObject:object forKey:key];
	[archiver finishEncoding];
	[archiver release];
}

- (id) decodeObjectForKey:(NSString*)key fromData:(NSData*)data {
	NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	id object = [unarchiver decodeObjectForKey:key];
	[unarchiver finishDecoding];
	[unarchiver release];
	return object;
}

@end
