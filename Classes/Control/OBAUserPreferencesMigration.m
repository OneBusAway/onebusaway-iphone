#import "OBAUserPreferencesMigration.h"

#import "OBAModel.h"
#import "OBABookmark.h"
#import "OBAStop.h"
#import "OBARoute.h"
#import "OBAStopPreferences.h"
#import "OBAStopAccessEvent.h"

#import "OBABookmarkV2.h"
#import "OBAStopPreferencesV2.h"
#import "OBAStopAccessEventV2.h"

#import "OBALogger.h"


@interface OBAUserPreferencesMigration (Private)

- (void) forceMigrateCoreDataPath:(NSString*)path toDao:(OBAModelDAO*)dao;
- (void) migrateStopPreferencesForStops:(NSArray*)stops withModelDao:(OBAModelDAO*)dao;
- (OBAModel*) fetchModelFromContext:(NSManagedObjectContext*)context;
- (NSArray*) fetchObjectsFromContext:(NSManagedObjectContext*)context ofType:(NSString*)typeName predicate:(NSPredicate*)predicate;

@end


@implementation OBAUserPreferencesMigration

- (void) migrateCoreDataPath:(NSString*)path toDao:(OBAModelDAO*)dao {

	NSFileManager * manager = [NSFileManager defaultManager];
	
	// If the database path doesn't exist, then we don't need to migrate
	if( ! [manager fileExistsAtPath:path] )
		return;
	
	[self forceMigrateCoreDataPath:path toDao:dao];
	
	[manager removeItemAtPath:path error:nil];
}

@end

@implementation OBAUserPreferencesMigration (Private)

- (void) forceMigrateCoreDataPath:(NSString*)path toDao:(OBAModelDAO*)dao {
	
	NSError * error = nil;
	
	NSManagedObjectModel * managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	NSPersistentStoreCoordinator * persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: managedObjectModel] autorelease];
	
	NSURL *storeUrl = [NSURL fileURLWithPath:path];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		OBALogSevereWithError(error,@"Error adding persistent store");
		return;
	}
		
	NSManagedObjectContext * managedObjectContext = [[NSManagedObjectContext alloc] init];
	[managedObjectContext setPersistentStoreCoordinator: persistentStoreCoordinator];
	
	OBAModel * model = [self fetchModelFromContext:managedObjectContext];

	if( ! model )
		return;
	
	// Transfer bookmarks
	NSMutableArray * bookmarks = [[NSMutableArray alloc] init];
	for( OBABookmark * bookmark in model.bookmarks )
		[bookmarks addObject:bookmark];
	[bookmarks sortUsingSelector:@selector(compareIndex:)];
	
	for( OBABookmark * bookmark in bookmarks) {
		OBAStop * stop = bookmark.stop;
		OBABookmarkV2 * v2 = [[OBABookmarkV2 alloc] init];
		v2.name = bookmark.name;
		v2.stopIds = [NSArray arrayWithObject:stop.stopId];
		[dao addNewBookmark:v2 error:nil];
	}
	[bookmarks release];
	
	// Transfer stop preferences
	// For reasons I don't understand, I couldn't get the OR of the two predicates to work, so I split them up
	NSPredicate * predicateA = [NSPredicate predicateWithFormat:@"preferences.sortTripsByType > 0"];
	NSArray * stopsA = [self fetchObjectsFromContext:managedObjectContext ofType:@"OBAStop" predicate:predicateA];
	[self migrateStopPreferencesForStops:stopsA withModelDao:dao];
	
	NSPredicate * predicateB = [NSPredicate predicateWithFormat:@"preferences.routesToExclude.@count > 0"];
	NSArray * stopsB = [self fetchObjectsFromContext:managedObjectContext ofType:@"OBAStop" predicate:predicateB];
	[self migrateStopPreferencesForStops:stopsB withModelDao:dao];
	
	// Transfer most recent stops
	NSMutableArray * recentStops = [[NSMutableArray alloc] init];
	for( OBAStopAccessEvent * event in model.recentStops )
		[recentStops addObject:event];
	[recentStops sortUsingSelector:@selector(compare:)];
	
	for( int i = [recentStops count]-1; i >= 0; i-- ) {
		OBAStopAccessEvent * event = [recentStops objectAtIndex:i];
		OBAStop * stop = event.stop;
		OBAStopAccessEventV2 * v2 = [[OBAStopAccessEventV2 alloc] init];
		v2.title = stop.title;
		v2.subtitle = stop.subtitle;
		v2.stopIds = [NSArray arrayWithObject:stop.stopId];
		[dao addStopAccessEvent:v2];
		[v2 release];
	}
	
	[recentStops release];
}

- (void) migrateStopPreferencesForStops:(NSArray*)stops withModelDao:(OBAModelDAO*)dao {
	
	if( ! stops )
		return;
	
	for( OBAStop * stop in stops) {
		OBAStopPreferences * prefs = stop.preferences;
		NSSet * routes = prefs.routesToExclude;
		if( [prefs.sortTripsByType intValue] == OBASortTripsByDepartureTime && [routes count] == 0)
			continue;
		OBAStopPreferencesV2 * p2 = [[OBAStopPreferencesV2 alloc] init];
		p2.sortTripsByType = [prefs.sortTripsByType intValue];
		for( OBARoute * route in routes )
			[p2 setEnabled:FALSE forRouteId:route.routeId];
		[dao setStopPreferences:p2 forStopWithId:stop.stopId];
	}
}

- (OBAModel*) fetchModelFromContext:(NSManagedObjectContext*)context {

	NSArray * fetchedObjects = [self fetchObjectsFromContext:context ofType:@"OBAModel" predicate:nil];
	
	if (fetchedObjects == nil) 
		return nil;
	
	if( [fetchedObjects count] == 0)
		return nil;

	if( [fetchedObjects count] > 1 ) {
		OBALogSevere(@"Duplicate entities: entityName=OBAModel count=%d",[fetchedObjects count]);
		return nil;
	}

	return [fetchedObjects objectAtIndex:0];
}

- (NSArray*) fetchObjectsFromContext:(NSManagedObjectContext*)context ofType:(NSString*)typeName predicate:(NSPredicate*)predicate {
	
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:typeName inManagedObjectContext:context];
	
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];	
	[request setEntity:entityDescription];
	if( predicate )
		[request setPredicate:predicate];

	NSError * error = nil;
	NSArray* fetchedObjects = [context executeFetchRequest:request error:&error];
	
	if (fetchedObjects == nil) {
		OBALogSevereWithError(error,@"Error fetching entity: type=%@", typeName);
		return nil;
	}

	return fetchedObjects;
}

@end

