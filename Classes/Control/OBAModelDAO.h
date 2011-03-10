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

#import "OBAStopV2.h"
#import "OBABookmarkV2.h"
#import "OBAStopAccessEventV2.h"
#import "OBAStopPreferencesV2.h"
#import "OBAActivityListeners.h"
#import "OBAServiceAlertsModel.h"


@class OBAModelDAOUserPreferencesImpl;

@interface OBAModelDAO : NSObject<OBAActivityListener> {
	OBAModelDAOUserPreferencesImpl * _preferencesDao;
	NSMutableArray * _bookmarks;
	NSMutableArray * _mostRecentStops;
	NSMutableDictionary * _stopPreferences;
	CLLocation * _mostRecentLocation;
	NSMutableSet * _visitedSituationIds;
}

@property (nonatomic,readonly) NSArray * bookmarks;
@property (nonatomic,readonly) NSArray * mostRecentStops;
@property (nonatomic,assign) CLLocation * mostRecentLocation;

- (OBABookmarkV2*) createTransientBookmark:(OBAStopV2*)stop;

- (void) addNewBookmark:(OBABookmarkV2*)bookmark error:(NSError**)error;
- (void) saveExistingBookmark:(OBABookmarkV2*)bookmark error:(NSError**)error;
- (void) moveBookmark:(NSInteger)startIndex to:(NSInteger)endIndex error:(NSError**)error;
- (void) removeBookmark:(OBABookmarkV2*) bookmark error:(NSError**)error;

- (void) addStopAccessEvent:(OBAStopAccessEventV2*)event;

- (OBAStopPreferencesV2*) stopPreferencesForStopWithId:(NSString*)stopId;
- (void) setStopPreferences:(OBAStopPreferencesV2*)preferences forStopWithId:(NSString*)stopId;

- (BOOL) isVisitedSituationWithId:(NSString*)situationId;
- (void) setVisited:(BOOL)visited forSituationWithId:(NSString*)situationId;

- (OBAServiceAlertsModel*) getServiceAlertsModelForSituations:(NSArray*)situations;

/**
 * We persist hiding location warnings across application settings for users who have disabled location services for the app
 */
- (BOOL) hideFutureLocationWarnings;
- (void) setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings;

@end
