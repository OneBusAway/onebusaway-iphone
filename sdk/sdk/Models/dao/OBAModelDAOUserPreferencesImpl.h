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

//#import <Foundation/Foundation.h>
#import "OBARegionV2.h"

@interface OBAModelDAOUserPreferencesImpl : NSObject  {

}

- (NSArray*) readBookmarks;
- (void) writeBookmarks:(NSArray*)source;

- (NSArray*) readBookmarkGroups;
- (void) writeBookmarkGroups:(NSArray*)source;

- (NSArray*) readMostRecentStops;
- (void) writeMostRecentStops:(NSArray*)source;

- (NSDictionary*) readStopPreferences;
- (void) writeStopPreferences:(NSDictionary*)stopPreferences;

- (CLLocation*) readMostRecentLocation;
- (void) writeMostRecentLocation:(CLLocation*)mostRecentLocation;

- (BOOL) hideFutureLocationWarnings;
- (void) setHideFutureLocationWarnings:(BOOL)hideFutureLocationWarnings;

- (NSSet*) readVisistedSituationIds;
- (void) writeVisistedSituationIds:(NSSet*)situationIds;

- (OBARegionV2*) readOBARegion;
- (void) writeOBARegion:(OBARegionV2*)oBARegion;

- (BOOL) readSetRegionAutomatically;
- (void) writeSetRegionAutomatically:(BOOL)setRegionAutomatically;

- (NSString*) readCustomApiUrl;
- (void) writeCustomApiUrl:(NSString*)customApiUrl;

- (NSArray*) readMostRecentCustomApiUrls;
- (void) writeMostRecentCustomApiUrls:(NSArray*)customApiUrls;

@end
