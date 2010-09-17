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


typedef enum {
	OBASortTripsByDepartureTime=0,
	OBASortTripsByRouteName=1
} OBASortTripsByType;

@class OBAStop;
@class OBARoute;

@interface OBAStopPreferences :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * sortTripsByType;
@property (nonatomic, retain) OBAStop * stop;
@property (nonatomic, retain) NSSet* routesToExclude;

@end


@interface OBAStopPreferences (CoreDataGeneratedAccessors)
- (void)addRoutesToExcludeObject:(OBARoute *)value;
- (void)removeRoutesToExcludeObject:(OBARoute *)value;
- (void)addRoutesToExclude:(NSSet *)value;
- (void)removeRoutesToExclude:(NSSet *)value;

@end

