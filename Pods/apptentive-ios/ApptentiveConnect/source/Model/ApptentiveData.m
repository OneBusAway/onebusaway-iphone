//
//  ApptentiveData.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 10/29/12.
//  Copyright (c) 2012 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveData.h"

#import "ApptentiveBackend.h"
#import "Apptentive_Private.h"
#import "ApptentiveLog.h"


@implementation ApptentiveData
+ (NSManagedObject *)newEntityNamed:(NSString *)entityName {
	NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];
	NSManagedObject *message = [[NSManagedObject alloc] initWithEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context] insertIntoManagedObjectContext:context];
	return message;
}

+ (NSArray *)findEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate {
	NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];
	NSFetchRequest *fetchType = [[NSFetchRequest alloc] initWithEntityName:entityName];
	fetchType.predicate = predicate;
	NSError *fetchError = nil;
	NSArray *fetchArray = [context executeFetchRequest:fetchType error:&fetchError];
	if (!fetchArray) {
		ApptentiveLogError(@"Error executing fetch request: %@", fetchError);
		fetchArray = nil;
	}
	fetchType = nil;

	return fetchArray;
}

+ (NSManagedObject *)findEntityWithURI:(NSURL *)URL {
	NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];
	NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:URL];
	if (objectID == nil) {
		return nil;
	}
	NSError *fetchError = nil;
	NSManagedObject *object = [context existingObjectWithID:objectID error:&fetchError];
	if (object == nil) {
		ApptentiveLogError(@"Error finding object with URL: %@", URL);
		ApptentiveLogError(@"Error was: %@", fetchError);
		return nil;
	}
	return object;
}

+ (NSUInteger)countEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate {
	NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];
	NSFetchRequest *fetchType = [[NSFetchRequest alloc] initWithEntityName:entityName];
	fetchType.predicate = predicate;
	NSError *fetchError = nil;
	NSUInteger count = [context countForFetchRequest:fetchType error:&fetchError];
	if (fetchError != nil) {
		ApptentiveLogError(@"Error executing fetch request: %@", fetchError);
		count = 0;
	}
	fetchType = nil;

	return count;
}

+ (void)removeEntitiesNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate {
	NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];
	NSFetchRequest *fetchTypes = [[NSFetchRequest alloc] initWithEntityName:entityName];
	fetchTypes.predicate = predicate;
	NSError *fetchError = nil;
	NSArray *fetchArray = [context executeFetchRequest:fetchTypes error:&fetchError];

	if (!fetchArray) {
		ApptentiveLogError(@"Error finding entities to remove: %@", fetchError);
	} else {
		for (NSManagedObject *fetchedObject in fetchArray) {
			[context deleteObject:fetchedObject];
		}
		[context save:nil];
	}

	fetchTypes = nil;
}

+ (void)deleteManagedObject:(NSManagedObject *)object {
	NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];
	[context deleteObject:object];
}

+ (BOOL)save {
	NSManagedObjectContext *context = [[Apptentive sharedConnection].backend managedObjectContext];
	NSError *error = nil;
	if (![context save:&error]) {
		ApptentiveLogError(@"Error saving context: %@", error);
		return NO;
	}
	return YES;
}

@end
