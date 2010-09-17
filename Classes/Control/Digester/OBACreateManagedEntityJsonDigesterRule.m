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

#import "OBACreateManagedEntityJsonDigesterRule.h"
#import "OBACommon.h"
#import "OBALogger.h"
#import "OBAEntityManager.h"


@implementation OBACreateManagedEntityJsonDigesterRule

- (id) initWithEntityName:(NSString*)entityName entityIdProperty:(NSString*)entityIdProperty jsonIdProperty:(NSString*)jsonIdProperty {
	if( self = [super init] ) {
		_entityName = [entityName retain];
		_entityIdProperty = [entityIdProperty retain];
		_jsonIdProperty = [jsonIdProperty retain];
	}
	return self;
}

- (void) dealloc {
	[_entityName release];
	[_entityIdProperty release];
	[_jsonIdProperty release];
	[super dealloc];
}

#pragma mark OBAJsonDigesterRule Methods

- (void) begin:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value  {
	
	if( ! [value isKindOfClass:[NSDictionary class]] ) {
		context.error = [NSError errorWithDomain:OBAErrorDomain code:kOBAErrorMissingFieldInData userInfo:nil];
		return;
	}
	
	NSDictionary * dict = value;
	id entityId = [dict objectForKey:_jsonIdProperty];
	
	if( entityId == nil ) {
		context.error = [NSError errorWithDomain:OBAErrorDomain code:kOBAErrorMissingFieldInData userInfo:nil];
		return;
	}
		
	NSError * error = nil;
	NSManagedObjectContext * managedObjectContext = [context getParameterForKey:@"managedObjectContext"];
	NSMutableDictionary * entityIdMappings = [context getParameterForKey:@"entityIdMappings"];
	
	id obj = [OBAEntityManager getEntityWithName:_entityName entityIdProperty:_entityIdProperty entityId:entityId fromContext:managedObjectContext withEntityIdMappings:entityIdMappings error:&error];

	if( error ) {
		context.error = error;
		return;
	}
	
	[context pushValue:obj];
}

- (void) end:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	[context popValue];
}

@end

