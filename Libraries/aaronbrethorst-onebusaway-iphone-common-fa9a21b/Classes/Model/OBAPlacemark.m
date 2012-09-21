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

#import "OBAPlacemark.h"


@implementation OBAPlacemark

@synthesize name = _name;
@synthesize address = _address;
@synthesize coordinate = _coordinate;
@synthesize icon = _icon;

-(id) initWithAddress:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate {
    self = [super init];
	if( self ) {
		_address = address;
		_coordinate = coordinate;
	}
	return self;
}

- (id) initWithCoder:(NSCoder*)coder {
    self = [super init];
	if( self ) {
        _name = [coder decodeObjectForKey:@"name"];
		_address =  [coder decodeObjectForKey:@"address"];
        _icon =  [coder decodeObjectForKey:@"icon"];
		NSData * data = [coder decodeObjectForKey:@"coordinate"];
		[data getBytes:&_coordinate];
	}
	return self;
}


- (CLLocation*) location {
    return [[CLLocation alloc] initWithLatitude:_coordinate.latitude longitude:_coordinate.longitude];
}

#pragma mark MKAnnotation

- (NSString*) title {
    if( _name )
        return _name;
	return _address;
}

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
    [coder encodeObject:_name forKey:@"name"];
	[coder encodeObject:_address forKey:@"address"];
    [coder encodeObject:_icon forKey:@"icon"];
	NSData * data = [NSData dataWithBytes:&_coordinate length:sizeof(CLLocationCoordinate2D)];
	[coder encodeObject:data forKey:@"coordinate"];
}

@end
