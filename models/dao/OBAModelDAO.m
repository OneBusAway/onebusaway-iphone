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
#import "OBAStopAccessEventV2.h"
#import "OBASituationV2.h"
#import "OBAModelDAOUserPreferencesImpl.h"


const static int kMaxEntriesInMostRecentList = 10;

@interface OBAModelDAO (Private)

- (void) saveMostRecentLocationLat:(double)lat lon:(double)lon;
- (NSInteger) getSituationSeverityAsNumericValue:(NSString*)severity;

@end

@implementation OBAModelDAO

- (id) init {
	if( self = [super init] ) {
		_preferencesDao = [[OBAModelDAOUserPreferencesImpl alloc] init];
		_bookmarks = [[NSMutableArray alloc] initWithArray:[_preferencesDao readBookmarks]];
		_mostRecentStops = [[NSMutableArray alloc] initWithArray:[_preferencesDao readMostRecentStops]];
		_stopPreferences = [[NSMutableDictionary alloc] initWithDictionary:[_preferencesDao readStopPreferences]];
		_mostRecentLocation = [_preferencesDao readMostRecentLocation];
		_visitedSituationIds = [[NSMutableSet alloc] initWithSet:[_preferencesDao readVisistedSituationIds]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordPlacemark:) name:OBAPlacemarkNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewedArrivalsAndDeparturesForStop:) name:OBAViewedArrivalsAndDeparturesForStopNotification object:nil];
	}
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OBAPlacemarkNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OBAViewedArrivalsAndDeparturesForStopNotification object:nil];
}

- (NSArray*) bookmarks {
	return _bookmarks;
}

- (NSArray*) mostRecentStops {
	return _mostRecentStops;
}

- (CLLocation*) mostRecentLocation {
	return _mostRecentLocation;
}

- (void) setMostRecentLocation:(CLLocation*)location {
	_mostRecentLocation = [NSObject releaseOld:_mostRecentLocation retainNew:location];
	[_preferencesDao writeMostRecentLocation:location];
}

- (void) addStopAccessEvent:(OBAStopAccessEventV2*)event {

	OBAStopAccessEventV2 * existingEvent = nil;
	
	NSArray * stopIds = event.stopIds;
	
	for( OBAStopAccessEventV2 * stopEvent in _mostRecentStops ) {
		if( [stopEvent.stopIds isEqual:stopIds] ) {
			existingEvent = stopEvent;
			break;
		}
	}
	
	if( existingEvent ) {
		[_mostRecentStops removeObject:existingEvent];
		[_mostRecentStops insertObject:existingEvent atIndex:0];
	}
	else {
		existingEvent = [[OBAStopAccessEventV2 alloc] init];
		existingEvent.stopIds = stopIds;
		[_mostRecentStops insertObject:existingEvent atIndex:0];

	}
	
	existingEvent.title = event.title;
	existingEvent.subtitle = event.subtitle;
	
	int over = [_mostRecentStops count] - kMaxEntriesInMostRecentList;
	for( int i=0; i<over; i++)
		[_mostRecentStops removeObjectAtIndex:([_mostRecentStops count]-1)];
	
	[_preferencesDao writeMostRecentStops:_mostRecentStops];	
}


- (OBABookmarkV2*) createTransientBookmark:(OBAStopV2*)stop {
	OBABookmarkV2 * bookmark = [[OBABookmarkV2 alloc] init];
	NSString * bookmarkName = stop.name;
	if( stop.direction )
		bookmarkName = [NSString stringWithFormat:@"%@ [%@]",stop.name,stop.direction];
	bookmark.name = bookmarkName;
	bookmark.stopIds = @[stop.stopId];
	return bookmark;
}

- (void) addNewBookmark:(OBABookmarkV2*)bookmark error:(NSError**)error {
	[_bookmarks addObject:bookmark];
	[_preferencesDao writeBookmarks:_bookmarks];
}

- (void) saveExistingBookmark:(OBABookmarkV2*)bookmark error:(NSError**)error {
	[_preferencesDao writeBookmarks:_bookmarks];
}

- (void) moveBookmark:(NSInteger)startIndex to:(NSInteger)endIndex error:(NSError**)error {
	OBABookmarkV2 * bm = _bookmarks[startIndex];
	[_bookmarks removeObjectAtIndex:startIndex];
	[_bookmarks insertObject:bm atIndex:endIndex];
	[_preferencesDao writeBookmarks:_bookmarks];
}

- (void) removeBookmark:(OBABookmarkV2*) bookmark error:(NSError**)error {
	[_bookmarks removeObject:bookmark];
	[_preferencesDao writeBookmarks:_bookmarks];
}

- (OBAStopPreferencesV2*) stopPreferencesForStopWithId:(NSString*)stopId {
	OBAStopPreferencesV2 * prefs = _stopPreferences[stopId];
	if( ! prefs )
		return [[OBAStopPreferencesV2 alloc] init];
	return [[OBAStopPreferencesV2 alloc] initWithStopPreferences:prefs];
}

- (void) setStopPreferences:(OBAStopPreferencesV2*)preferences forStopWithId:(NSString*)stopId {
	_stopPreferences[stopId] = preferences;
	[_preferencesDao writeStopPreferences:_stopPreferences];
}

#pragma mark OBAActivityListener

- (void)recordPlacemark:(NSNotification*)note {
    OBAPlacemark * placemark = [note object];
    CLLocationCoordinate2D coordinate = placemark.coordinate;
	[self saveMostRecentLocationLat:coordinate.latitude lon:coordinate.longitude];
}

- (void)viewedArrivalsAndDeparturesForStop:(NSNotification*)note {
    OBAStopV2* stop = [note object];
	OBAStopAccessEventV2 * event = [[OBAStopAccessEventV2 alloc] init];
	event.stopIds = @[stop.stopId];
	event.title = stop.title;
	event.subtitle = stop.subtitle;
	[self addStopAccessEvent:event];
}

- (BOOL) hideFutureLocationWarnings {
	return [_preferencesDao hideFutureLocationWarnings];
}

- (void) setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings {
	[_preferencesDao setHideFutureLocationWarnings:hideFutureLocationWarnings];
}

- (BOOL) isVisitedSituationWithId:(NSString*)situationId {
	return [_visitedSituationIds containsObject:situationId];
}

- (OBAServiceAlertsModel*) getServiceAlertsModelForSituations:(NSArray*)situations {

	OBAServiceAlertsModel * model = [[OBAServiceAlertsModel alloc] init];

	model.totalCount = [situations count];
	
	NSInteger maxUnreadSeverityValue = -99;
	NSInteger maxSeverityValue = -99;
	
	for( OBASituationV2 * situation in situations ) {
		
		NSString * severity = situation.severity;
		NSInteger severityValue = [self getSituationSeverityAsNumericValue:severity];

		if( ! [self isVisitedSituationWithId:situation.situationId] ) {
			
			model.unreadCount++;
			
			if( model.unreadMaxSeverity == nil || severityValue > maxUnreadSeverityValue) {
				model.unreadMaxSeverity = severity;
				maxUnreadSeverityValue = severityValue;
			}
		}
		
		if( model.maxSeverity == nil || severityValue > maxSeverityValue) {
			model.maxSeverity = severity;
			maxSeverityValue = severityValue;
		}
	}	
	
	return model;
}


- (void) setVisited:(BOOL)visited forSituationWithId:(NSString*)situationId {
	
	BOOL prevVisited = [_visitedSituationIds containsObject:situationId];

	if( visited != prevVisited ) {
		if( visited ) 
			[_visitedSituationIds addObject:situationId];
		else 
			[_visitedSituationIds removeObject:situationId];
		
		[_preferencesDao writeVisistedSituationIds:_visitedSituationIds];
	}
}


@end


@implementation OBAModelDAO (Private)

- (void) saveMostRecentLocationLat:(double)lat lon:(double)lon {	
	CLLocation * location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
	[self setMostRecentLocation:location];
}

- (NSInteger) getSituationSeverityAsNumericValue:(NSString*)severity {
	if( ! severity )
		return -1;
	if( [severity isEqualToString:@"noImpact"] )
		return -2;
	if( [severity isEqualToString:@"undefined"] )
		return -1;
	if( [severity isEqualToString:@"unknown"] )
		return 0;
	if( [severity isEqualToString:@"verySlight"] )
		return 1;
	if( [severity isEqualToString:@"slight"] )
		return 2;
	if( [severity isEqualToString:@"normal"] )
		return 3;
	if( [severity isEqualToString:@"normal"] )
		return 4;
	if( [severity isEqualToString:@"normal"] )
		return 5;
	return -1;
}

@end

