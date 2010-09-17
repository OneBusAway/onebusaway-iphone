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

#import "OBAActivityLogger.h"
#import "SBJSON.h"
#import "OBALogger.h"
#import "OBAApplicationContext.h"
#import "OBATripStatus.h"
#import "OBALogger.h"


NSString * const kActivityNameKey = @"name";
NSString * const kActivityTimeKey = @"time";

static OBAActivityLogger * _staticInstance = nil;


@interface OBAActivityLogger (Private)

- (NSMutableDictionary*) getActivityRecord:(NSString*)activityName;
- (void) writeJSONRecord:(NSDictionary*)dictionary toLogger:(OBARotatingLogger*)logger;

@end


@implementation OBAActivityLogger

@synthesize context = _context;

-(id) init {
	if( self = [super init] ) {
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		
		NSString * locationPath =[NSString stringWithFormat:@"%@/Location",documentsDirectory];
		NSString * accelerometerPath =[NSString stringWithFormat:@"%@/Accelerometer",documentsDirectory];
		NSString * activityPath =[NSString stringWithFormat:@"%@/Activity",documentsDirectory];
		
		_locationLogger = [[OBARotatingLogger alloc] initWithDirectory:locationPath withMaxFileSize:100*1024];
		_accelerometerLogger = [[OBARotatingLogger alloc] initWithDirectory:accelerometerPath withMaxFileSize:10*1024*1024];
		_activityLogger = [[OBARotatingLogger alloc] initWithDirectory:activityPath withMaxFileSize:100*1024];
		
		_staticInstance = self;
		_running = NO;
	}
	return self;
}

-(void) dealloc {
	[self stop];
	[_context release];
	[_locationLogger release];
	[_accelerometerLogger release];
	[_activityLogger release];
	[super dealloc];
}

+ (OBAActivityLogger*) getLogger {
	return _staticInstance;
}

-(NSArray*) getLogFilePaths {
	NSMutableArray * logFilePaths = [NSMutableArray arrayWithCapacity:0];
	[logFilePaths addObjectsFromArray:_locationLogger.individualTracePaths];
	[logFilePaths addObjectsFromArray:_accelerometerLogger.individualTracePaths];
	[logFilePaths addObjectsFromArray:_activityLogger.individualTracePaths];
	return logFilePaths;
}

-(void) deleteAllTraces {
	
	BOOL wasRunning = _running;
	
	if( wasRunning )
		[self stop];
	
	NSFileManager * manager = [NSFileManager defaultManager];
	for( NSString * path in [self getLogFilePaths] ) {
		NSError * error = nil;
		[manager removeItemAtPath:path error:&error];
		if( error )
			OBALogSevereWithError(error,@"error deleting path: %@", path);
			
	}
	
	if( wasRunning )
		[self start];
}

-(void) start {
	
	@synchronized(self) {
		
		if( _running )
			return;
		
		[_locationLogger open];
		[_accelerometerLogger open];
		[_activityLogger open];
		
		if( kIncludeUWActivityLocationLogging ) {
			[_context.locationManager addDelegate:self];
		}
		
		if( kIncludeUWActivityAccelerometerLogging ) {
			UIAccelerometer * accel = [UIAccelerometer sharedAccelerometer];
			[accel setDelegate:self];
		}
		
		[_context.activityListeners addListener:self];
		
		_running = YES;
	}
}

-(void) stop {
	
	@synchronized(self) {
		
		if( ! _running )
			return;
		
		if( kIncludeUWActivityLocationLogging ) {
			[_context.locationManager removeDelegate:self];
		}
		
		if( kIncludeUWActivityAccelerometerLogging ) {
			UIAccelerometer * accel = [UIAccelerometer sharedAccelerometer];
			[accel setDelegate:nil];
		}
		
		[_context.activityListeners removeListener:self];
		
		[_locationLogger close];
		[_accelerometerLogger close];
		[_activityLogger close];
		
		_running = NO;
	}
}

- (void)locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location {
	NSDate * timestamp = location.timestamp;
	
	CLLocationCoordinate2D coord = location.coordinate;
	NSString * line = [NSString stringWithFormat:@"v1,%f,%f,%f,%f\n",[timestamp timeIntervalSince1970],coord.latitude,coord.longitude,location.horizontalAccuracy];
	[_locationLogger write:line];
}

- (void) locationManager:(OBALocationManager *)manager didFailWithError:(NSError*)error {
	
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
	double t = CFAbsoluteTimeGetCurrent();
	NSString * line = [NSString stringWithFormat:@"v2,%f,%f,%f,%f,%f\n",acceleration.timestamp,t,acceleration.x,acceleration.y,acceleration.z];
	[_accelerometerLogger write:line];	
}

#pragma mark OBAActivityListener Methods

- (void) bookmarkClicked:(OBABookmark*)bookmark {
	NSMutableDictionary * dict = [self getActivityRecord:@"bookmarkClicked"];
	[dict setObject:bookmark.name forKey:@"bookmarkName"];
	[dict setObject:bookmark.stop.stopId forKey:@"stopId"];
	[self writeJSONRecord:dict toLogger:_activityLogger];
}

- (void) viewedArrivalsAndDeparturesForStop:(OBAStop*)stop {
	NSMutableDictionary * dict = [self getActivityRecord:@"viewArrivalsAndDeparturesForStop"];
	[dict setObject:stop.stopId forKey:@"stopId"];
	[self writeJSONRecord:dict toLogger:_activityLogger];	
}

- (void) annotationWithLabel:(NSString*)label {
	NSMutableDictionary * dict = [self getActivityRecord:@"annotationWithLabel"];
	[dict setObject:label forKey:@"annotationLabel"];
	[self writeJSONRecord:dict toLogger:_activityLogger];
}

- (void) nearbyTrips:(NSArray*)nearbyTrips {
	NSMutableDictionary * dict = [self getActivityRecord:@"nearbyTrips"];
	NSMutableArray * elements = [NSMutableArray array];
	
	for( OBATripStatus * tripStatus in nearbyTrips ) {
		NSMutableDictionary * element = [NSMutableDictionary dictionary];
		OBATrip * trip = tripStatus.trip;
		CLLocation * position =  tripStatus.position;
		CLLocationCoordinate2D coordinates = position.coordinate;
		int predicted = tripStatus.predicted ? 1 : 0;
		
		[element setObject:trip.tripId forKey:@"tripId"];
		[element setObject:[NSNumber numberWithLongLong:tripStatus.serviceDate] forKey:@"serviceDate"];
		[element setObject:[NSNumber numberWithDouble:coordinates.latitude] forKey:@"lat"];
		[element setObject:[NSNumber numberWithDouble:coordinates.longitude] forKey:@"lon"];
		[element setObject:[NSNumber numberWithInt:tripStatus.scheduleDeviation] forKey:@"scheduleDeviation"];
		[element setObject:[NSNumber numberWithInt:predicted] forKey:@"predicted"];
		 
		[elements addObject:element];
	}
	
	[dict setObject:elements forKey:@"trips"];
	[self writeJSONRecord:dict toLogger:_activityLogger];
}

@end

@implementation OBAActivityLogger (Private)

- (NSMutableDictionary*) getActivityRecord:(NSString*)activityName {
	
	NSMutableDictionary * dict = [NSMutableDictionary dictionary];
	[dict setObject:activityName forKey:kActivityNameKey];
	NSDate * now = [NSDate date];
	[dict setObject:[NSNumber numberWithDouble:[now timeIntervalSince1970]] forKey:kActivityTimeKey];
	return dict;
}	

- (void) writeJSONRecord:(NSDictionary*)dictionary toLogger:(OBARotatingLogger*)logger {
	
	SBJSON * parser = [[SBJSON alloc] init];
	NSError * error = nil;
	NSString * recordAsString = [parser stringWithObject:dictionary error:&error];
	[parser release];

	if( error ) {
		OBALogSevereWithError(error,@"Error converting activity record to JSON: record=%@",[dictionary description]);
		return;
	}
	
	NSString * line = [NSString stringWithFormat:@"%@\n",recordAsString];
	[logger write:line];	
}

@end