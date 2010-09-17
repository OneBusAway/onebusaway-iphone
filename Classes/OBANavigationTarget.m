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

#import "OBANavigationTarget.h"


@implementation OBANavigationTarget

@synthesize target = _target;
@synthesize parameters = _parameters;

- (id) initWithTarget:(OBANavigationTargetType)target {
	return [self initWithTarget:target parameters:[NSDictionary dictionary]];
}

- (id) initWithTarget:(OBANavigationTargetType)target parameters:(NSDictionary*)parameters {
	if( self = [super init] ) {
		_target = target;
		_parameters = [[NSMutableDictionary alloc] initWithDictionary:parameters];
	}
	return self;
}

- (id) initWithCoder:(NSCoder*)coder {
	if( self = [super init] ) {
		
		NSNumber * target = [coder decodeObjectForKey:@"target"];
		_target = [target intValue];

		NSDictionary * dictionary = [coder decodeObjectForKey:@"parameters"];
		_parameters = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
	}
	return self;
}

+ (id) target:(OBANavigationTargetType)target {
	return [[[self alloc] initWithTarget:target] autorelease];	
}

+ (id) target:(OBANavigationTargetType)target parameters:(NSDictionary*)parameters {
	return [[[self alloc] initWithTarget:target parameters:parameters] autorelease];
}


- (void) dealloc {
	[_parameters release];
	[super dealloc];
}

- (id) parameterForKey:(id)key {
	return [_parameters objectForKey:key];
}

- (void) setParameter:(id)value forKey:(id)key {
	[_parameters setObject:value forKey:key];
}

#pragma mark NSCoder Methods

- (void) encodeWithCoder: (NSCoder *)coder {
	[coder encodeObject:[NSNumber numberWithInt:_target] forKey:@"target"];
	[coder encodeObject:_parameters forKey:@"parameters"];
}


@end
