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

//#import <CoreData/CoreData.h>

@class OBARoute;
@class OBAStopAccessEvent;
@class OBAStopPreferences;
@class OBABookmark;

@interface OBAStop :  NSManagedObject <MKAnnotation>
{
}


@property (nonatomic, strong) NSString * stopId;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * code;
@property (nonatomic, strong) NSString * direction;
@property (nonatomic, strong) NSNumber * latitude;
@property (nonatomic, strong) NSNumber * longitude;
@property (nonatomic, strong) NSSet* routes;
@property (nonatomic, strong) NSSet* accessEvents;
@property (nonatomic, strong) OBAStopPreferences * preferences;
@property (nonatomic, strong) NSSet* bookmarks;

@property (nonatomic,readonly) double lat;
@property (nonatomic,readonly) double lon;

- (NSString*) routeNamesAsString;
- (NSComparisonResult) compareUsingName:(OBAStop*)aStop;

@end


@interface OBAStop (CoreDataGeneratedAccessors)
- (void)addRoutesObject:(OBARoute *)value;
- (void)removeRoutesObject:(OBARoute *)value;
- (void)addRoutes:(NSSet *)value;
- (void)removeRoutes:(NSSet *)value;

- (void)addAccessEventsObject:(OBAStopAccessEvent *)value;
- (void)removeAccessEventsObject:(OBAStopAccessEvent *)value;
- (void)addAccessEvents:(NSSet *)value;
- (void)removeAccessEvents:(NSSet *)value;

- (void)addBookmarksObject:(OBABookmark *)value;
- (void)removeBookmarksObject:(OBABookmark *)value;
- (void)addBookmarks:(NSSet *)value;
- (void)removeBookmarks:(NSSet *)value;

@end

