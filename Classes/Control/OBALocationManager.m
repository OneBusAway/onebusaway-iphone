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

#import "OBALocationManager.h"
#import "OBACommon.h"

@implementation OBALocationManager

@synthesize currentLocation = _currentLocation;

-(id) init {
	if( self = [super init]) {
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;
		_delegates = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void) dealloc {
	[_locationManager release];
	[_delegates release];
	[super dealloc];
}

- (BOOL) locationServicesEnabled {
	return _locationManager.locationServicesEnabled;
}

- (void) addDelegate:(id<OBALocationManagerDelegate>)delegate {
	@synchronized(self) {
		[_delegates addObject:delegate];
	}
}

- (void) removeDelegate:(id<OBALocationManagerDelegate>)delegate {
	@synchronized(self) {
		[_delegates removeObject:delegate];
	}
}

-(void) startUpdatingLocation {
	[_locationManager startUpdatingLocation];
}

-(void) stopUpdatingLocation {
	[_locationManager stopUpdatingLocation];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {

#if TARGET_IPHONE_SIMULATOR
	newLocation = [[[CLLocation alloc] initWithLatitude:  47.653435121376894 longitude: -122.3056411743164] autorelease];
	//newLocation = [[[CLLocation alloc] initWithLatitude:  47.60983759756863 longitude: -122.33782768249512] autorelease];
#endif
	
	@synchronized(self) {
		_currentLocation = [NSObject releaseOld:_currentLocation retainNew:newLocation];

		for( id<OBALocationManagerDelegate> delegate in _delegates )
			[delegate locationManager:self didUpdateLocation:_currentLocation];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {

	if( [error code] == kCLErrorDenied ) {
		[self stopUpdatingLocation];
	}
}

@end

