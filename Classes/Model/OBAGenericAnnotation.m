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

#import "OBAGenericAnnotation.h"


@implementation OBAGenericAnnotation

@synthesize coordinate = _coordinate;

- (id) initWithTitle:(NSString*)title subtitle:(NSString*)subtitle coordinate:(CLLocationCoordinate2D)coordinate context:(id)context {
	if( self = [super init] ) {
		_title = [title retain];
		_subtitle = [subtitle retain];
		_coordinate = coordinate;
		_context = [context retain];
	}
	return self;
}

- (void) dealloc {
	[_title release];
	[_subtitle release];
	[_context release];
	[super dealloc];
}

- (NSString*) title {
	return _title;
}

- (NSString*) subtitle {
	return _subtitle;
}

- (id) context {
	return _context;
}

@end
