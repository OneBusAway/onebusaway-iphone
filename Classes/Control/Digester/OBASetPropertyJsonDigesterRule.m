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

#import "OBASetPropertyJsonDigesterRule.h"


@implementation OBASetPropertyJsonDigesterRule

- (id) initWithPropertyName:(NSString*)propertyName {
	if( self = [super init] ) {
		[self initWithPropertyName:propertyName onlyIfNeeded:FALSE];
		_propertyName = [propertyName retain];		
	}
	return self;
}

- (id) initWithPropertyName:(NSString*)propertyName onlyIfNeeded:(BOOL)onlyIfNeeded {
	if( self = [super init] ) {
		_propertyName = [propertyName retain];		
		_onlyIfNeeded = onlyIfNeeded;
	}
	return self;
	
}

- (void) dealloc {
	[_propertyName release];
	[super dealloc];
}

- (void) begin:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	
	NSObject * top = [context peek:0];
	
	if( _onlyIfNeeded ) {
		id existingValue = [top valueForKey:_propertyName];
		if( [existingValue isEqual:value] )
			return;
	}
	
	[top setValue:value forKey:_propertyName];
}

@end
