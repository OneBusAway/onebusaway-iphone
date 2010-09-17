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

#import "OBAStopAnnotation.h"
#import "OBARoute.h"


@implementation OBAStopAnnotation

- (id) initWithStop:(OBAStop*)stop {
	if( self = [super init] ) {
		_stop = [stop retain];
	}
	return self;
}

- (void) dealloc {
	[_stop release];
	[super dealloc];
}

- (OBAStop*) stop {
	return _stop;
}

- (CLLocationCoordinate2D) coordinate {
	CLLocationCoordinate2D c = {_stop.lat,_stop.lon};
	return c;
}

- (NSString*) title {
	return _stop.name;
}

- (NSString*) subtitle {
	NSMutableString * label = [NSMutableString string];
	[label appendString:@"Routes: "];
	BOOL first = TRUE;
	
	for( OBARoute * route in _stop.routes ) {
		if( first )
			first = FALSE;
		else
			[label  appendString:@", "];
		[label appendString: route.shortName];
	}
	return label;
}

@end
