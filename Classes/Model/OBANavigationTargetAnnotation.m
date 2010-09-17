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

#import "OBANavigationTargetAnnotation.h"


@implementation OBANavigationTargetAnnotation

@synthesize title = _title;
@synthesize subtitle = _subtitle;
@synthesize coordinate = _coordinate;
@synthesize target = _target;
@synthesize data = _data;

- (id) initWithTitle:(NSString*)title subtitle:(NSString*)subtitle coordinate:(CLLocationCoordinate2D)coordinate target:(OBANavigationTarget*)target {

	if( self = [super init] ) {
		_title = [title retain];
		_subtitle = [subtitle retain];
		_coordinate = coordinate;
		_target = [target retain];
	}
	
	return self;
}

- (void) dealloc {
	[_title release];
	[_subtitle release];
	[_target release];
	[_data release];
	[super dealloc];
}

@end
