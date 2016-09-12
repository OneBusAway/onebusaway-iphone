//
//  ApptentiveDataManager.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 5/12/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveDataManager.h"

// Used to indicate a database upgrade or check was in progress and didn't complete.
NSString *const ATDataManagerUpgradeCanaryFilename = @"ATDataManagerUpgradeCanary";

typedef enum {
	ATMigrationMergedModelErrorCode = -100,
	ATMigrationNoModelsFoundErrorCode = -101,
	ATMigrationNoMatchingModelFoundErrorCode = -102,
} ATMigrationErrorCode;


@interface ApptentiveDataManager (Migration)
- (BOOL)isMigrationNecessary:(NSPersistentStoreCoordinator *)psc;
- (BOOL)migrateStoreError:(NSError **)error;
- (BOOL)progressivelyMigrateURL:(NSURL *)sourceStoreURL ofType:(NSString *)type toModel:(NSManagedObjectModel *)finalModel error:(NSError **)error;
- (BOOL)removeSQLiteSidecarsForPath:(NSString *)sourcePath;
@end


@interface ApptentiveDataManager ()


@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

@property (readwrite, nonatomic) BOOL didRemovePersistentStore;
@property (readwrite, nonatomic) BOOL didFailToMigrateStore;
@property (readwrite, nonatomic) BOOL didMigrateStore;

@property (copy, nonatomic) NSString *modelName;
@property (strong, nonatomic) NSBundle *bundle;
@property (copy, nonatomic) NSString *supportDirectoryPath;

@end


@implementation ApptentiveDataManager

- (id)initWithModelName:(NSString *)aModelName inBundle:(NSBundle *)aBundle storagePath:(NSString *)path {
	if ((self = [super init])) {
		_modelName = aModelName;
		_bundle = aBundle;
		_supportDirectoryPath = path;

		// Check the canary.
		if ([self canaryFileExists]) {
			[self removePersistentStore];
			[self removeCanaryFile];
		}
	}
	return self;
}

#pragma mark Properties
- (NSManagedObjectContext *)managedObjectContext {
	@synchronized(self) {
		if (_managedObjectContext != nil) {
			return _managedObjectContext;
		}

		NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
		if (coordinator != nil) {
			_managedObjectContext = [[NSManagedObjectContext alloc] init];
			[_managedObjectContext setPersistentStoreCoordinator:coordinator];
		}
	}
	return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
	if (_managedObjectModel != nil) {
		return _managedObjectModel;
	}
	NSURL *modelURL = [self.bundle URLForResource:self.modelName withExtension:@"momd"];
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	return _managedObjectModel;
}

- (BOOL)setupAndVerify {
	// Set the canary.
	if (![self createCanaryFile]) {
		return NO;
	}

	if (![self persistentStoreCoordinator]) {
		// This is almost certainly something bad.
		return NO;
	}

	NSManagedObjectContext *moc = [self managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	@try {
		// Due to a migration error from v2 to v3, these items may not have customData fields.
		[request setEntity:[NSEntityDescription entityForName:@"ATMessage" inManagedObjectContext:moc]];
		[request setFetchBatchSize:20];
		NSArray *results = [moc executeFetchRequest:request error:nil];
		for (NSManagedObject *c in results) {
			__unused NSObject *d = [c valueForKey:@"customData"];
			break;
		}
	}
	@catch (NSException *exception) {
		ApptentiveLogError(@"Caught exception attempting to test classes: %@", exception);
		self.managedObjectContext = nil;
		self.persistentStoreCoordinator = nil;
		ApptentiveLogError(@"Removing persistent store and starting over.");
		[self removePersistentStore];
	}
	@finally {
		request = nil;
	}

	if (![self persistentStoreCoordinator]) {
		return NO;
	}
	// Seems to have gone well, so remove canary.
	if (![self removeCanaryFile]) {
		return NO;
	}
	return YES;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	@synchronized(self) {
		if (_persistentStoreCoordinator != nil) {
			return _persistentStoreCoordinator;
		}

		NSURL *storeURL = [self persistentStoreURL];

		NSError *error = nil;
		@try {
			_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		}
		@catch (NSException *exception) {
			ApptentiveLogError(@"Unable to setup persistent store: %@", exception);
			return nil;
		}
		BOOL storeExists = [[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]];

		if (storeExists && [self isMigrationNecessary:_persistentStoreCoordinator]) {
			if (![self migrateStoreError:&error]) {
				ApptentiveLogError(@"Failed to migrate store. Need to start over from scratch: %@", error);
				self.didFailToMigrateStore = YES;
				[self removePersistentStore];
			} else {
				self.didMigrateStore = YES;
			}
		}

		// By default, the value of NSPersistentStoreFileProtectionKey is:
		// iOS 4 and earlier: NSFileProtectionNone
		// iOS 5 and later: NSFileProtectionCompleteUntilFirstUserAuthentication
		// So, there's no need to set these explicitly for our purposes.
		NSDictionary *options = @{ NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"} };
		if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
			ApptentiveLogError(@"Unable to create new persistent store: %@", error);
			_persistentStoreCoordinator = nil;
			return nil;
		}
	}
	return _persistentStoreCoordinator;
}

#pragma mark -
- (NSURL *)persistentStoreURL {
	NSString *sqliteFilename = [self.modelName stringByAppendingPathExtension:@"sqlite"];
	return [[NSURL fileURLWithPath:self.supportDirectoryPath] URLByAppendingPathComponent:sqliteFilename];
}

- (void)removePersistentStore {
	NSURL *storeURL = [self persistentStoreURL];
	NSString *sourcePath = [storeURL path];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	if ([fileManager fileExistsAtPath:sourcePath]) {
		NSError *error = nil;
		if (![[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]) {
			ApptentiveLogError(@"Failed to delete the store: %@", error);
		}
	}
	[self removeSQLiteSidecarsForPath:sourcePath];
	self.didRemovePersistentStore = YES;
}

#pragma mark - Upgrade Canary
- (NSString *)canaryFilePath {
	return [self.supportDirectoryPath stringByAppendingPathComponent:ATDataManagerUpgradeCanaryFilename];
}

- (BOOL)canaryFileExists {
	BOOL isDirectory = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:[self canaryFilePath] isDirectory:&isDirectory] && !isDirectory) {
		return YES;
	}
	return NO;
}

- (BOOL)createCanaryFile {
	NSDictionary *data = @{ @"upgrading": @YES };
	return [data writeToFile:[self canaryFilePath] atomically:YES];
}

- (BOOL)removeCanaryFile {
	NSError *error = nil;
	if ([[NSFileManager defaultManager] removeItemAtPath:[self canaryFilePath] error:&error]) {
		return YES;
	}
	ApptentiveLogError(@"Error removing upgrade canary: %@", error);
	return NO;
}
@end


@implementation ApptentiveDataManager (Migration)

- (BOOL)isMigrationNecessary:(NSPersistentStoreCoordinator *)psc {
	NSString *sourceStoreType = NSSQLiteStoreType;
	NSURL *sourceStoreURL = [self persistentStoreURL];

	NSError *error = nil;

	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:sourceStoreType URL:sourceStoreURL error:&error];
	if (sourceMetadata == nil) {
		return YES;
	}
	NSManagedObjectModel *destinationModel = [psc managedObjectModel];
	BOOL isCompatible = [destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
	return !isCompatible;
}

- (BOOL)migrateStoreError:(NSError **)error {
	NSString *sourceStoreType = NSSQLiteStoreType;
	NSURL *sourceStoreURL = [self persistentStoreURL];
	return [self progressivelyMigrateURL:sourceStoreURL ofType:sourceStoreType toModel:[self managedObjectModel] error:error];
}

- (BOOL)progressivelyMigrateURL:(NSURL *)sourceStoreURL ofType:(NSString *)type toModel:(NSManagedObjectModel *)finalModel error:(NSError **)error {
	NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:type URL:sourceStoreURL error:error];
	if (sourceMetadata == nil) {
		return NO;
	}
	if ([finalModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata]) {
		if (error) {
			*error = nil;
		}
		return YES;
	}

	// Find source model.
	NSArray *bundlesForSourceModel = @[self.bundle];
	NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:bundlesForSourceModel forStoreMetadata:sourceMetadata];
	if (sourceModel == nil) {
		ApptentiveLogError(@"Failed to find source model.");
		if (error) {
			*error = [NSError errorWithDomain:@"ATErrorDomain" code:ATMigrationMergedModelErrorCode userInfo:@{ NSLocalizedDescriptionKey: @"Failed to find source model for migration" }];
		}
		return NO;
	}

	NSMutableArray *modelPaths = [NSMutableArray array];
	NSArray *momdPaths = [self.bundle pathsForResourcesOfType:@"momd" inDirectory:nil];

	for (NSString *momdPath in momdPaths) {
		NSString *resourceSubpath = [momdPath lastPathComponent];
		NSArray *array = [self.bundle pathsForResourcesOfType:@"mom" inDirectory:resourceSubpath];
		[modelPaths addObjectsFromArray:array];
	}

	NSArray *otherModels = [self.bundle pathsForResourcesOfType:@"mom" inDirectory:nil];
	[modelPaths addObjectsFromArray:otherModels];

	if (!modelPaths || ![modelPaths count]) {
		if (error) {
			*error = [NSError errorWithDomain:@"ATErrorDomain" code:ATMigrationNoModelsFoundErrorCode userInfo:@{ NSLocalizedDescriptionKey: @"No models found in bundle" }];
		}
		return NO;
	}

	// Find matching destination model.
	NSMappingModel *mappingModel = nil;
	NSManagedObjectModel *targetModel = nil;
	NSString *modelPath = nil;
	NSArray *bundlesForTargetModel = @[self.bundle];
	for (modelPath in modelPaths) {
		targetModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
		mappingModel = [NSMappingModel mappingModelFromBundles:bundlesForTargetModel forSourceModel:sourceModel destinationModel:targetModel];
		if (mappingModel) {
			break;
		}
		targetModel = nil;
	}

	if (!mappingModel) {
		if (error) {
			*error = [NSError errorWithDomain:@"ATErrorDomain" code:ATMigrationNoMatchingModelFoundErrorCode userInfo:@{ NSLocalizedDescriptionKey: @"No matching migration found in bundle" }];
		}
		return NO;
	}

	// Mapping model and destination model found. Migrate them.
	NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:targetModel];
	NSString *localModelName = [[modelPath lastPathComponent] stringByDeletingPathExtension];
	NSString *storeExtension = [[sourceStoreURL path] pathExtension];
	NSString *storePath = [[sourceStoreURL path] stringByDeletingPathExtension];
	storePath = [NSString stringWithFormat:@"%@.%@.%@", storePath, localModelName, storeExtension];
	NSURL *destinationStoreURL = [NSURL fileURLWithPath:storePath];

	NSDictionary *options = @{ NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"} };
	if (![manager migrateStoreFromURL:sourceStoreURL type:type options:nil withMappingModel:mappingModel toDestinationURL:destinationStoreURL destinationType:type destinationOptions:options error:error]) {
		manager = nil;
		return NO;
	}
	manager = nil;

	// Move files around.
	NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
	guid = [guid stringByAppendingPathExtension:localModelName];
	guid = [guid stringByAppendingPathExtension:storeExtension];
	NSString *appSupportPath = [storePath stringByDeletingLastPathComponent];
	NSString *backupPath = [appSupportPath stringByAppendingPathComponent:guid];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager moveItemAtPath:[sourceStoreURL path] toPath:backupPath error:error]) {
		ApptentiveLogError(@"Unable to backup source store path.");
		return NO;
	}

	if (![fileManager moveItemAtPath:storePath toPath:[sourceStoreURL path] error:error]) {
		[fileManager moveItemAtPath:backupPath toPath:[sourceStoreURL path] error:nil];
		ApptentiveLogError(@"Unable to move new store into place.");
		return NO;
	} else {
		// Kill any remaining -wal or -shm files. Kill them with fire.
		// See: http://pablin.org/2013/05/24/problems-with-core-data-migration-manager-and-journal-mode-wal/
		// Also: http://stackoverflow.com/questions/17487306/ios-coredata-are-there-any-disadvantages-to-enabling-sqlite-wal-write-ahead
		NSString *sourcePath = [sourceStoreURL path];
		[self removeSQLiteSidecarsForPath:sourcePath];
	}

	return [self progressivelyMigrateURL:sourceStoreURL ofType:type toModel:finalModel error:error];
}

- (BOOL)removeSQLiteSidecarsForPath:(NSString *)sourcePath {
	NSArray *extensions = @[@"-shm", @"-wal"];
	BOOL success = YES;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	for (NSString *ext in extensions) {
		NSString *obsoletePath = [sourcePath stringByAppendingString:ext];
		BOOL isDir = NO;
		NSError *localError = nil;
		if ([fileManager fileExistsAtPath:obsoletePath isDirectory:&isDir] && !isDir) {
			if (![fileManager removeItemAtPath:obsoletePath error:&localError]) {
				ApptentiveLogError(@"Unable to remove obsolete WAL file %@ with error: %@", obsoletePath, localError);
				success = NO;
			}
		}
	}
	return success;
}
@end
