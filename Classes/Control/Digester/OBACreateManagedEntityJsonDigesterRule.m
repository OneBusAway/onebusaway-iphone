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


@interface OBACreateManagedEntityJsonDigesterRule (Private)

- (id) getEntityWithEntityId:(id)entityId fromContext:(id<OBAJsonDigesterContext>)context error:(NSError**)error;
- (NSManagedObjectID*) getManagedObjectIdForEntityWithId:(NSString*)entityId withContext:(id<OBAJsonDigesterContext>)context;
- (void) setManagedObjectIdForEntityWithId:(NSString*)entityId managedObjectId:(NSManagedObjectID*)managedObjectId context:(id<OBAJsonDigesterContext>)context;
- (NSMutableDictionary*) getEntityIdMappings:(id<OBAJsonDigesterContext>)context;

@end


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
	id obj = [self getEntityWithEntityId:entityId fromContext:context error:&error];
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

@implementation OBACreateManagedEntityJsonDigesterRule (Private)

- (id) getEntityWithEntityId:(id)entityId fromContext:(id<OBAJsonDigesterContext>)context error:(NSError**)error {
	
	NSManagedObjectContext * managedObjectContext = [context getParameterForKey:@"managedObjectContext"];
	NSManagedObjectID * managedObjectId = [self getManagedObjectIdForEntityWithId:entityId withContext:context];
	
	if( managedObjectId != nil ) {
		NSError * error = nil;
		NSManagedObject * obj = [managedObjectContext existingObjectWithID:managedObjectId error:&error];
		if( error ) {
			NSString * uri = [[managedObjectId URIRepresentation] absoluteString];
			OBALogSevereWithError(error,@"Error retrievingExistingObjectWithID: entityName=%@ entityId=%@ managedId=%@",_entityName,entityId,uri);
		}
		else {
			if( [entityId isEqual:[obj valueForKey:_entityIdProperty]] )
				return obj;
			NSString * uri = [[managedObjectId URIRepresentation] absoluteString];
			OBALogWarning(@"Entity id mismatch: entityName=%@ entityId=%@ managedId=%@",_entityName,entityId,uri);
		}
	}
	
	NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:_entityName inManagedObjectContext:managedObjectContext];
	
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", _entityIdProperty, entityId];
	[request setPredicate:predicate];
	
	NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:request error:error];
	
	if (fetchedObjects == nil) {
		OBALogSevereWithError((*error),@"Error fetching entity: name=%@ idProperty=%@ id=%@",_entityName,_entityIdProperty,entityId);
		return nil;
	}
	
	if( [fetchedObjects count] == 0) {
		id entity = [NSEntityDescription insertNewObjectForEntityForName:_entityName inManagedObjectContext:managedObjectContext];
		[entity setValue:entityId forKey:_entityIdProperty];
		return entity;
	}
	
	if( [fetchedObjects count] > 1 ) {
		OBALogSevere(@"Duplicate entities: entityName=%@ entityIdProperty=%@ entityId=%@ count=%d",_entityName,_entityIdProperty,entityId,[fetchedObjects count]);
		(*error) = [NSError errorWithDomain:OBAErrorDomain code:kOBAErrorDuplicateEntity userInfo:nil];
		return nil;
	}
	
	NSManagedObject * entity = [fetchedObjects objectAtIndex:0];
	[self setManagedObjectIdForEntityWithId:entityId managedObjectId:[entity objectID] context:context];
	return entity;
}

- (NSManagedObjectID*) getManagedObjectIdForEntityWithId:(NSString*)entityId withContext:(id<OBAJsonDigesterContext>)context {
	NSDictionary * entityIdMappings = [self getEntityIdMappings:context];
	NSDictionary * entityIdMapping = [entityIdMappings objectForKey:_entityName];
	if( entityIdMapping == nil )
		return nil;
	return [entityIdMapping objectForKey:entityId];
}

- (void) setManagedObjectIdForEntityWithId:(NSString*)entityId managedObjectId:(NSManagedObjectID*)managedObjectId context:(id<OBAJsonDigesterContext>)context {
	NSMutableDictionary * entityIdMappings = [self getEntityIdMappings:context];
	NSMutableDictionary * entityIdMapping = [entityIdMappings objectForKey:_entityName];
	if( entityIdMapping == nil ) {
		entityIdMapping = [NSMutableDictionary dictionary];
		[entityIdMappings setObject:entityIdMapping forKey:_entityName];
	}
	[entityIdMapping setObject:managedObjectId forKey:entityId];
}

- (NSMutableDictionary*) getEntityIdMappings:(id<OBAJsonDigesterContext>)context {
	NSMutableDictionary * entityIdMappings = [context getParameterForKey:@"entityIdMappings"];
	if( ! entityIdMappings ) {
		entityIdMappings = [NSMutableDictionary dictionary];
		[context setParamter:entityIdMappings forKey:@"entityIdMappings"];
	}
	return entityIdMappings;
}

@end

