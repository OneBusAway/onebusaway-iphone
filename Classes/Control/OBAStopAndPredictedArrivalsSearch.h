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

#import "OBAApplicationContext.h"
#import "OBAStopSource.h"
#import "OBAPredictedArrivalsSource.h"

#import "OBAJsonDataSource.h"
#import "OBAModelFactory.h"
#import "OBAModelDAO.h"
#import "OBADataSource.h"

@class OBAProgressIndicatorImpl;

@interface OBAStopAndPredictedArrivalsSearch : NSObject <OBAStopSource,OBAPredictedArrivalsSource,OBADataSourceDelegate> {
	
	OBAApplicationContext * _context;
	
	OBAJsonDataSource * _jsonDataSource;
	OBAModelFactory * _modelFactory;
	OBAModelDAO * _modelDao;
	
	NSString * _stopId;
	OBAStopV2 * _stop;
	NSArray * _predictedArrivals;
	OBAProgressIndicatorImpl * _progress;
	NSError * _error;
	NSTimer * _timer;
	
	UIBackgroundTaskIdentifier _bgTask;
}

@property (retain,readwrite) OBAStopV2 * stop;
@property (retain,readwrite) NSArray * predictedArrivals;
@property (retain,readonly) NSObject<OBAProgressIndicatorSource>* progress;
@property (retain,readwrite) NSError * error;

- (id) initWithContext:(OBAApplicationContext*)context;

- (void) searchForStopId:(NSString*)stopId;

- (OBANavigationTarget*) getSearchTarget;
-(void) setSearchTarget:(OBANavigationTarget*) target;

- (void) cancelOpenConnections;

@end

extern NSString* OBARefreshBeganNotification;
extern NSString* OBARefreshEndedNotification;
