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

#import "OBAEntityManager.h"
#import "OBACommon.h"
#import "OBALogger.h"


@interface OBAEntityManager (Internal)

+ (NSManagedObjectID*) getManagedObjectIdForEntityName:(NSString*)entityName entityId:(NSString*)entityId entityIdMappings:(NSDictionary*)entityIdMappings;
+ (void) setManagedObjectIdForEntityName:(NSString*)entityName entityId:(NSString*)entityId managedObjectId:(NSManagedObjectID*)managedObjectId entityIdMappings:(NSMutableDictionary*)entityIdMappings;

@end


@implementation OBAEntityManager

+ (id) getEntityWithName:(NSString*)entityName entityIdProperty:(NSString*)entityIdProperty entityId:(id)entityId fromContext:(NSManagedObjectContext*)managedObjectContext withEntityIdMappings:(NSMutableDictionary*)entityIdMappings error:(NSError**)error {

	NSManagedObjectID * managedObjectId = [self getManagedObjectIdForEntityName:entityName entityId:entityId entityIdMappings:entityIdMappings];
	
	if( managedObjectId != nil ) {
		NSError * error = nil;
		NSManagedObject * obj = [managedObjectContext existingObjectWithID:managedObjectId error:&error];
		if( error ) {
			NSString * uri = [[managedObjectId URIRepresentation] absoluteString];
			OBALogSevereWithError(error,@"Error retrievingExistingObjectWithID: entityName=%@ entityId=%@ managedId=%@",entityName,entityId,uri);
		}
		else {
			if( [entityId isEqual:[obj valueForKey:entityIdProperty]] )
				return obj;
			NSString * uri = [[managedObjectId URIRepresentation] absoluteString];
			OBALogWarning(@"Entity id mismatch: entityName=%@ entityId=%@ managedId=%@",entityName,entityId,uri);
		}
	}
	
	NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:entityName inManagedObjectContext:managedObjectContext];
	
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:entityDescription];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", entityIdProperty, entityId];
	[request setPredicate:predicate];
	
	NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:request error:error];
	
	if (fetchedObjects == nil) {
		OBALogSevereWithError((*error),@"Error fetching entity: name=%@ idProperty=%@ id=%@",entityName,entityIdProperty,entityId);
		return nil;
	}
	
	if( [fetchedObjects count] == 0) {
		id entity = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:managedObjectContext];
		[entity setValue:entityId forKey:entityIdProperty];
		return entity;
	}
	
	if( [fetchedObjects count] > 1 ) {
		OBALogSevere(@"Duplicate entities: entityName=%@ entityIdProperty=%@ entityId=%@ count=%d",entityName,entityIdProperty,entityId,[fetchedObjects count]);
      
        if (error != NULL)
            (*error) = [NSError errorWithDomain:OBAErrorDomain code:kOBAErrorDuplicateEntity userInfo:nil];
		return nil;
	}
	
	NSManagedObject * entity = [fetchedObjects objectAtIndex:0];
	[self setManagedObjectIdForEntityName:entityName entityId:entityId managedObjectId:[entity objectID] entityIdMappings:entityIdMappings];
	return entity;
}

@end

@implementation OBAEntityManager (Internal)

+ (NSManagedObjectID*) getManagedObjectIdForEntityName:(NSString*)entityName entityId:(NSString*)entityId entityIdMappings:(NSDictionary*)entityIdMappings {
	NSDictionary * entityIdMapping = [entityIdMappings objectForKey:entityName];
	if( entityIdMapping == nil )
		return nil;
	return [entityIdMapping objectForKey:entityId];
}

+ (void) setManagedObjectIdForEntityName:(NSString*)entityName entityId:(NSString*)entityId managedObjectId:(NSManagedObjectID*)managedObjectId entityIdMappings:(NSMutableDictionary*)entityIdMappings {
	
	NSMutableDictionary * entityIdMapping = [entityIdMappings objectForKey:entityName];
	if( entityIdMapping == nil ) {
		entityIdMapping = [NSMutableDictionary dictionary];
		[entityIdMappings setObject:entityIdMapping forKey:entityName];
	}
	[entityIdMapping setObject:managedObjectId forKey:entityId];
}

@end