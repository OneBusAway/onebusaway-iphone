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

#import "OBAModelDAO.h"
#import "OBALogger.h"
#import "OBACommon.h"
#import "OBAStopAccessEvent.h"

const static int kMaxEntriesInMostRecentList = 10;

@interface OBAModelDAO (Private)

- (void) reindexBookmarks;
- (void) saveMostRecentLocationLat:(double)lat lon:(double)lon;

@end

@implementation OBAModelDAO

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	
	if( self = [super init] ) {
		_context = [managedObjectContext retain];
	}
	return self;
}

- (void) dealloc {
	[_model release];
	[_context release];
	[super dealloc];
}

- (void) setup:(NSError**)error {
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"OBAModel" inManagedObjectContext:_context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSArray *fetchedObjects = [_context executeFetchRequest:request error:error];
	
	if (fetchedObjects == nil) {
		OBALogSevereWithError((*error),@"Error fetching entity: name=OBAModel");
		return;
	}
	
	if( [fetchedObjects count] == 0) {
		_model = [NSEntityDescription insertNewObjectForEntityForName:@"OBAModel" inManagedObjectContext:_context];
		[_model retain];
		[_context save:error];
		return;
	}
	
	if( [fetchedObjects count] > 1 ) {
		OBALogSevere(@"Duplicate entities: entityName=OBAModel count=%d",[fetchedObjects count]);
		(*error) = [NSError errorWithDomain:OBAErrorDomain code:kOBAErrorDuplicateEntity userInfo:nil];
		return;
	}
	
	_model = [fetchedObjects objectAtIndex:0];
	[_model retain];
}

- (NSArray*) bookmarks {
	NSMutableArray * bookmarks = [NSMutableArray array];
	for( OBABookmark * bookmark in _model.bookmarks )
		[bookmarks addObject:bookmark];
	[bookmarks sortUsingSelector:@selector(compareIndex:)];
	return bookmarks;
}

- (NSArray*) mostRecentStops {
	NSMutableArray * stopAccessEvents = [NSMutableArray array];
	for( OBAStopAccessEvent * event in _model.recentStops )
		[stopAccessEvents addObject:event];
	[stopAccessEvents sortUsingSelector:@selector(compare:)];
	return stopAccessEvents;
}

- (CLLocation*) mostRecentLocation {
	return _model.mostRecentLocation;
}

#pragma mark OBAActivityListener

- (void) placemark:(OBAPlacemark*)placemark {
	CLLocationCoordinate2D coordinate = placemark.coordinate;
	[self saveMostRecentLocationLat:coordinate.latitude lon:coordinate.longitude];
}

- (void) viewedArrivalsAndDeparturesForStop:(OBAStop*)stop {

	BOOL found = FALSE;
	
	[self saveMostRecentLocationLat:stop.lat lon:stop.lon];
	
	for( OBAStopAccessEvent * event in _model.recentStops ) {
		if( [event.stop isEqual:stop] ) {
			event.eventTime = [NSDate date];
			found = TRUE;
			break;
		}
	}
	
	if( ! found ) {	
		OBAStopAccessEvent * event = [NSEntityDescription insertNewObjectForEntityForName:@"OBAStopAccessEvent" inManagedObjectContext:_context];
		event.eventTime = [NSDate date];
		event.stop = stop;
		event.model = _model;
		[_model addRecentStopsObject:event];
	}
	
	int over = [_model.recentStops count] - kMaxEntriesInMostRecentList;
	if( over > 0 ) {
		NSArray * mostRecent = [self mostRecentStops];
		for( int i=0; i<over; i++) {
			OBAStopAccessEvent * event = [mostRecent objectAtIndex:([mostRecent count]-1-i)];
			[_model removeRecentStopsObject:event];
			[_context deleteObject:event];
		}
	}
	
	NSError * error = nil;
	[self saveIfNeeded:&error];

	if( error )
		OBALogWarningWithError(error,@"error saving state for viewedArrivalsAndDeparturesForStop event");
}

- (OBABookmark*) createTransientBookmark:(OBAStop*)stop {
	OBABookmark * bookmark = [NSEntityDescription insertNewObjectForEntityForName:@"OBABookmark" inManagedObjectContext:_context];
	bookmark.name = stop.name;
	bookmark.stop = stop;
	return bookmark;
}

- (void) addNewBookmark:(OBABookmark*)bookmark error:(NSError**)error {
	NSInteger count = [_model.bookmarks count];
	bookmark.index = [NSNumber numberWithInt:count];
	[_model addBookmarksObject:bookmark];
	[self reindexBookmarks];
	[self saveIfNeeded:error];
}

- (void) saveExistingBookmark:(OBABookmark*)bookmark error:(NSError**)error {
	[self saveIfNeeded:error];
}

- (void) moveBookmark:(NSInteger)startIndex to:(NSInteger)endIndex error:(NSError**)error {
	
	NSMutableArray * bms = [NSMutableArray arrayWithArray: self.bookmarks];
	OBABookmark * bm = [bms objectAtIndex:startIndex];
	[bms removeObjectAtIndex:startIndex];
	[bms insertObject:bm atIndex:endIndex];

	for( int index = 0; index < [bms count]; index++) {
		OBABookmark * bm = [bms objectAtIndex:index];		
		if( [bm.index intValue] != index )
			bm.index = [NSNumber numberWithInt:index];
	}

	[self saveIfNeeded:error];
}

- (void) removeBookmark:(OBABookmark*) bookmark error:(NSError**)error {
	[_model removeBookmarksObject:bookmark];
	[_context deleteObject:bookmark];
	[self saveIfNeeded:error];
}

- (void) saveIfNeeded:(NSError**)error {
	if( [_context hasChanges] )
		[_context save:error];
}

- (void) rollback {
	[_context rollback];
}



@end

@implementation OBAModelDAO (Private)

- (void) reindexBookmarks {
	
	NSArray * bms = [self bookmarks];
	
	for( int index = 0; index < [bms count]; index++) {
		OBABookmark * bm = [bms objectAtIndex:index];		
		if( [bm.index intValue] != index )
			bm.index = [NSNumber numberWithInt:index];
	}
}

- (void) saveMostRecentLocationLat:(double)lat lon:(double)lon {
	
	CLLocation * location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
	_model.mostRecentLocation = location;
	[location release];

	NSError * error = nil;	
	[self saveIfNeeded:&error];
	if( error )
		OBALogWarningWithError(error,@"Error saving most recent location");
}



@end

