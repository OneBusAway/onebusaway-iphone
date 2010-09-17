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
static NSString * kMostRecentStops = @"mostRecentStops";
static NSString * kStopPreferencesKey = @"stopPreferences";

@implementation OBAModelDAOUserPreferencesImpl

- (BOOL) openModel {	
	return YES;
}

- (BOOL) closeModel {
	return YES;
}

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
	NSData * data = [user dataForKey:kMostRecentStops];
	NSArray * stops = nil;
	@try {
		stops = [self decodeObjectForKey:kMostRecentStops fromData:data];
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
	[self encodeObject:source forKey:kMostRecentStops toData:data];
	[user setObject:data forKey:kMostRecentStops];
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
