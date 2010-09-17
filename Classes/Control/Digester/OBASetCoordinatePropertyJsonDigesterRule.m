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

#import "OBASetCoordinatePropertyJsonDigesterRule.h"

@interface OBASetCoordinatePropertyJsonDigesterRule (Private)

- (void) arrayMethod:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) latLonMethod:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value;
- (void) setCoordinate:(id<OBAJsonDigesterContext>)context name:(NSString*)name lat:(NSNumber*)lat lon:(NSNumber*)lon;

@end


@implementation OBASetCoordinatePropertyJsonDigesterRule

- (id) initWithPropertyName:(NSString*)propertyName method:(OBASetCoordinatePropertyMethod) method {
	if( self = [super initWithPropertyName:propertyName] ) {
		_method = method;
	}
	return self;
}

- (void) begin:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	
	switch(_method) {
		case OBASetCoordinatePropertyMethodArray:
			[self arrayMethod:context name:name value:value];
			break;
		case OBASetCoordinatePropertyMethodLatLon:
			[self latLonMethod:context name:name value:value];
			break;
	}
}

@end

@implementation OBASetCoordinatePropertyJsonDigesterRule (Private)

- (void) arrayMethod:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {

	if( ! [value isKindOfClass:[NSArray class]] )
		return;
	
	NSArray * array = (NSArray*)value;
	
	if( [array count] < 2 )
		return;
	
	NSNumber * longitude = [array objectAtIndex:0];
	NSNumber * latitude = [array objectAtIndex:1];
	
	[self setCoordinate:context name:name lat:latitude lon:longitude];
}

- (void) latLonMethod:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {

	if( ! [value isKindOfClass:[NSDictionary class]] )
		return;
	
	NSDictionary * dictionary = (NSDictionary*)value;
	
	NSNumber * latitude = [dictionary objectForKey:@"lat"];
	NSNumber * longitude = [dictionary objectForKey:@"lon"];
	
	[self setCoordinate:context name:name lat:latitude lon:longitude];
}

- (void) setCoordinate:(id<OBAJsonDigesterContext>)context name:(NSString*)name lat:(NSNumber*)lat lon:(NSNumber*)lon {
	CLLocationCoordinate2D coordinate = {[lat doubleValue], [lon doubleValue]};	
	NSValue * v = [NSValue value:&coordinate withObjCType:@encode(CLLocationCoordinate2D)];
	[super begin:context name:name value:v];
}

@end
