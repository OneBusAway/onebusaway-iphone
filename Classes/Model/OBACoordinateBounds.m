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

#import "OBACoordinateBounds.h"


@implementation OBACoordinateBounds

@synthesize empty = _empty;

- (id) init {
	if( self = [super init] ) {
		_empty = TRUE;
	}
	return self;
}

+ (id) bounds {
	return [[[OBACoordinateBounds alloc] init] autorelease];
}

- (MKCoordinateRegion) region {
	return MKCoordinateRegionMake([self center],[self span]);
}

- (CLLocationCoordinate2D) center {
	CLLocationCoordinate2D center = {0.0,0.0};
	if( ! _empty ) {
		center.latitude = (_minLatitude + _maxLatitude)/2;
		center.longitude = (_minLongitude + _maxLongitude)/2;
	}
	return center;
}

- (MKCoordinateSpan) span {
	MKCoordinateSpan span = MKCoordinateSpanMake(0.0,0.0);
	if( ! _empty ) {
		span.latitudeDelta = _maxLatitude - _minLatitude;
		span.longitudeDelta = _maxLongitude - _minLongitude;
	}
	return span;
}

- (void) addCoordinate:(CLLocationCoordinate2D)coordinate {
	if( _empty ) {
		_empty = FALSE;

		_minLatitude = coordinate.latitude;
		_maxLatitude = coordinate.latitude;
		_minLongitude = coordinate.longitude;
		_maxLongitude = coordinate.longitude;
	}
	else {
		_minLatitude = MIN(_minLatitude,coordinate.latitude);
		_maxLatitude = MAX(_maxLatitude,coordinate.latitude);
		_minLongitude = MIN(_minLongitude,coordinate.longitude);
		_maxLongitude = MAX(_maxLongitude,coordinate.longitude);
	}
}

@end
