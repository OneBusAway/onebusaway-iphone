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

#import "OBAStopAndPredictedArrivalsSearch.h"
#import "OBAArrivalAndDeparture.h"
#import "OBAProgressIndicatorImpl.h"
#import "OBACommon.h"
#import "OBAJsonDataSource.h"
#import "UIDeviceExtensions.h"


NSString* OBARefreshBeganNotification = @"OBARefreshBeganNotification";
NSString* OBARefreshEndedNotification = @"OBARefreshEndedNotification";


@implementation OBAStopAndPredictedArrivalsSearch

@synthesize minutesAfter = _minutesAfter;

@synthesize stop = _stop;
@synthesize predictedArrivals = _predictedArrivals;
@synthesize progress = _progress;
@synthesize error = _error;

- (id) initWithContext:(OBAApplicationContext*)context {
	if( self = [super init] ) {
		_context = [context retain];
		_progress = [[OBAProgressIndicatorImpl alloc] init];
		_jsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:context.obaDataSourceConfig];
		_modelFactory = [context.modelFactory retain];
		_modelDao = [context.modelDao retain];
        
		_minutesAfter = 35;
		
        if ([[UIDevice currentDevice] isMultitaskingSupportedSafe])
            _bgTask = UIBackgroundTaskInvalid;
	}
	return self;
}
	
- (void) dealloc {
	[self cancelOpenConnections];
	
	[_stopId release];
	[_stop release];
	[_predictedArrivals release];
	[_progress release];	
	[_error release];
	
	[_jsonDataSource release];
	[_modelFactory release];
	[_modelDao release];
	
	[_context release];
	
	[super dealloc];
}

- (void) searchForStopId:(NSString*)stopId {
	_stopId = [stopId retain];
	[self refresh];
}

- (OBANavigationTarget*)getSearchTarget {
	if( ! _stopId )
		return nil;

	NSDictionary * params = [NSDictionary dictionaryWithObject:_stopId forKey:@"stopId"];
	return [OBANavigationTarget target:OBANavigationTargetTypeStop parameters:params];
}

-(void)setSearchTarget:(OBANavigationTarget*) target {
	NSString * stopId = [target parameterForKey:@"stopId"];
	[self searchForStopId:stopId];
}

- (void)cancelOpenConnections {
	if( _timer ) {
		[_timer invalidate];
		[_timer release];
		_timer = nil;
	}

	[_jsonDataSource cancelOpenConnections];
}

// check if we support background task completion; if so, end bg task
- (void) endBgTask {
    if ([[UIDevice currentDevice] isMultitaskingSupportedSafe]) {
        if (_bgTask != UIBackgroundTaskInvalid) {
            UIApplication* app = [UIApplication sharedApplication];
            [app endBackgroundTask:_bgTask];
            _bgTask = UIBackgroundTaskInvalid;   
        }
	}
}

- (void)refresh {
	if( _stopId ) {
		// send "began" notification.
		[[NSNotificationCenter defaultCenter] postNotificationName:OBARefreshBeganNotification object:self];		
		
		[_progress setMessage:@"Updating..." inProgress:TRUE progress:0];

		if( ! _timer ) {
			_timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh) userInfo:nil repeats:TRUE];
			[_timer retain];
		}

		// if we support background task completion (iOS >= 4.0), allow our refreshes to be completed
		// even if the user switches the foreground application.
		if ([[UIDevice currentDevice] isMultitaskingSupportedSafe]) {
			// if we're already refreshing, don't do another one.
			if (_bgTask != UIBackgroundTaskInvalid)
				return;
			
			UIApplication* app = [UIApplication sharedApplication];
			_bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
				[self endBgTask];
			}];
		}
		
		NSString *url = [NSString stringWithFormat:@"/api/where/arrivals-and-departures-for-stop/%@.json", _stopId];
		NSString * args = [NSString stringWithFormat:@"version=2&minutesAfter=%d",_minutesAfter];
						   
		[_jsonDataSource requestWithPath:url withArgs:args withDelegate:self context:nil];	
	}
}

- (void)connectionDidFinishLoading:(id<OBADataSourceConnection>)connection withObject:(id)obj context:(id)context {
	// debugging code: display how many times a stop controller has been refreshed.
	// helpful for background completion.
	const  BOOL gDebugRefreshing     = NO;
	static int  gDebugTimesRefreshed = 1;
	
	NSNumber * code = [obj valueForKey:@"code"];
	
	if( code == nil || [code intValue] != 200 ) {
		if( code != nil && [code intValue] == 404 )
			[_progress setMessage:@"Stop not found" inProgress:FALSE progress:0];
		else
			[_progress setMessage:@"Unknown error" inProgress:FALSE progress:0];
		return;
	}
	
	NSDictionary * data = [obj valueForKey:@"data"];
	
	NSError * localError = nil;	
	OBAArrivalsAndDeparturesForStopV2 * ads = [_modelFactory getArrivalsAndDeparturesForStopV2FromJSON:data error:&localError];
	if( localError ) {
		self.error = localError;
		return;
	}
	
	// Note the event
	OBAStopV2 * stop = ads.stop;
	[_context.activityListeners viewedArrivalsAndDeparturesForStop:stop];

	// Update the page
	self.stop = stop;
	self.predictedArrivals = ads.arrivalsAndDepartures;
	self.error = nil;
	
	NSString * message = [NSString stringWithFormat:@"Updated: %@", [OBACommon getTimeAsString]];

	if (gDebugRefreshing) {
		message = [NSString stringWithFormat:@"%@ (%d)", message, gDebugTimesRefreshed];
		
		OBAArrivalAndDeparture * ad = [self.predictedArrivals objectAtIndex:0];
		if (ad != nil)
			ad.routeShortName = [NSString stringWithFormat:@"(%d)", gDebugTimesRefreshed++];
	}
						  
	[_progress setMessage:message inProgress:FALSE progress:0];

	// send "done" notification.
	[[NSNotificationCenter defaultCenter] postNotificationName:OBARefreshEndedNotification object:self];
	
	// end bg task
	[self endBgTask];
}

- (void)connection:(id<OBADataSourceConnection>)connection withProgress:(float)progress {
	[_progress setInProgress:TRUE progress:progress];
}

- (void)connectionDidFail:(id<OBADataSourceConnection>)connection withError:(NSError *)error context:(id)context {
	self.error = error;
	[_progress setMessage:@"Error connecting" inProgress:FALSE progress:0];
	
	// send "done" notification.
	[[NSNotificationCenter defaultCenter] postNotificationName:OBARefreshEndedNotification object:self];	
	
	// end bg task
	[self endBgTask];
}

@end
