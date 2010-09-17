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

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <SystemConfiguration/SystemConfiguration.h>

#import "OBAApplicationContext.h"
#import "OBANavigationTargetAware.h"
#import "OBALogger.h"

#import "OBASearchResultsMapViewController.h"
#import "OBABookmarksViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBASearchViewController.h"
#import "OBASearchController.h"
#import "OBASettingsViewController.h"
#import "OBAStopViewController.h"

#import "OBAActivityLoggingViewController.h"
#import "OBAActivityAnnotationViewController.h"
#import "OBAUploadViewController.h"
#import "OBALockViewController.h"

#import "OBANearbyTripsController.h"

static NSString * kOBAHiddenPreferenceLocationAwareDisabled = @"OBALocationAwareDisabled";
static NSString * kOBAHiddenPreferenceSavedNavigationTargets = @"OBASavedNavigationTargets";
static NSString * kOBAHiddenPreferenceApplicationTerminationTimestamp = @"OBAApplicationTerminationTimestamp";
static NSString * kOBAHiddenPreferenceUserId = @"OBAApplicationUserId";

static NSString * kOBAPreferenceShowOnStartup = @"oba_show_on_start_preference";
static NSString * kOBAPreferenceClearLocalCacheOnStartup = @"oba_clear_local_cache_preference";

static const double kMaxTimeSinceApplicationTerminationToRestoreState = 15*60;
static const BOOL kDeleteModelOnStartup = FALSE;

@interface OBAApplicationContext (Private)

- (void) setup;
- (void) teardown;

- (void) saveApplicationNavigationState;
- (void) restoreApplicationNavigationState;

- (void) setNavigationTarget:(OBANavigationTarget*)target forViewController:(UIViewController*)viewController;
- (UIViewController*) getViewControllerForTarget:(OBANavigationTarget*)target;

- (NSString *)applicationDocumentsDirectory;

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults;

@end


@implementation OBAApplicationContext

@synthesize locationManager = _locationManager;
@synthesize activityListeners = _activityListeners;

@synthesize obaDataSourceConfig = _obaDataSourceConfig;
@synthesize googleMapsDataSourceConfig = _googleMapsDataSourceConfig;

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

@synthesize active = _active;
@synthesize locationAware = _locationAware;

- (id) init {
	if( self = [super init] ) {

		_setup = FALSE;
		_active = FALSE;
		_locationAware = TRUE;

	}
	return self;
}

- (void) dealloc {
	
	[_managedObjectContext release];
	[_modelDao release];
	
	[_locationManager release];
	[_nearbyTripsController release];
	[_activityListeners release];
	
	[_obaDataSourceConfig release];
	[_googleMapsDataSourceConfig release];
	
	if( kIncludeUWActivityInferenceCode )
		[_activityLogger release];
	
	[_window release];
	[_tabBarController release];
	
	[super dealloc];
}

- (void) navigateToTarget:(OBANavigationTarget*)navigationTarget {
	
	switch (navigationTarget.target) {
		case OBANavigationTargetTypeSearchResults: {
			UINavigationController * mapNavController = [_tabBarController.viewControllers objectAtIndex:0];
			OBASearchResultsMapViewController * searchResultsMapViewController = [mapNavController.viewControllers objectAtIndex:0];
			[searchResultsMapViewController setNavigationTarget:navigationTarget];
			_tabBarController.selectedIndex = 0;
			[mapNavController  popToRootViewControllerAnimated:FALSE];
			break;
		}
	}
}

- (OBAModelDAO*) modelDao {
	if( ! _modelDao )
		[self setup];
	return _modelDao;
}

- (OBAModelFactory*) modelFactory {
	if( ! _modelFactory )
		[self setup];
	return _modelFactory;
}


#pragma mark UIApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	
	[self setup];
	
	_tabBarController.delegate = self;

	UIView * rootView = [_tabBarController view];
	[_window addSubview:rootView];
	[_window makeKeyAndVisible];
	
	OBANavigationTarget * navTarget = [OBASearchControllerFactory getNavigationTargetForSearchCurrentLocation];
	[self navigateToTarget:navTarget];
	
	[self restoreApplicationNavigationState];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	_active = TRUE;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	_active = FALSE;
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
	CLLocation * location = _locationManager.currentLocation;
	if( location )
		_modelDao.mostRecentLocation = location;
	
	[self saveApplicationNavigationState];	
	[self teardown];
}

#pragma mark UITabBarControllerDelegate Methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
	int index = tabBarController.selectedIndex;
	if( index == 0 || index == 1 || index == 2 ) {
		UINavigationController * rootNavController = (UINavigationController*) _tabBarController.selectedViewController;
		[rootNavController  popToRootViewControllerAnimated:FALSE];
	}
	return YES;
}

@end

@implementation OBAApplicationContext (Private)

- (void) setup {
	
	if( _setup )
		return;
	
	_setup = TRUE;
	_active = TRUE;
	NSError * error = nil;
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSFileManager * manager = [NSFileManager defaultManager];

	NSString * apiServerName = [userDefaults objectForKey:@"oba_api_server"];
	if( apiServerName == nil || [apiServerName length] == 0 )
		apiServerName = @"api.onebusaway.org";
	
	apiServerName = [NSString stringWithFormat:@"http://%@",apiServerName];
	
	NSString * userId = [self userIdFromDefaults:userDefaults];
	NSString * appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString * obaArgs = [NSString stringWithFormat:@"key=org.onebusaway.iphone&app_uid=%@&app_ver=%@",userId,appVersion];
	
	//_obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://soak-api.onebusaway.org" args:obaArgs];
	//_obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://api.onebusaway.org" args:obaArgs];
	_obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:apiServerName args:obaArgs];		
	
	//_obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://localhost:8080/onebusaway-api-webapp" args:@"key=org.onebusaway.iphone"];
	_googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://maps.google.com" args:@"output=json&oe=utf-8&key=ABQIAAAA1R_R0bUhLYRwbQFpKHVowhRAXGY6QyK0faTs-0G7h9EE_iri4RRtKgRdKFvvraEP5PX_lP_RlqKkzA"];
	
	_locationManager = [[OBALocationManager alloc] init];		
	_activityListeners = [[OBAActivityListeners alloc] init];		
	
	if( kIncludeUWActivityInferenceCode ) {
		_activityLogger = [[OBAActivityLogger alloc] init];
		_activityLogger.context = self;
		_nearbyTripsController = [[OBANearbyTripsController alloc] initWithApplicationContext:self];
	}
	
	NSString * path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"OneBusAway.sqlite"];

	BOOL clearCacheOnStartup = [userDefaults boolForKey:kOBAPreferenceClearLocalCacheOnStartup];
	[userDefaults setBool:FALSE forKey:kOBAPreferenceClearLocalCacheOnStartup];
	
	if( clearCacheOnStartup || kDeleteModelOnStartup ) {

		if( ! [manager removeItemAtPath:path error:&error] )
			OBALogSevereWithError(error,@"Error deleting file: %@",path);
		
		[userDefaults removeObjectForKey:kOBAHiddenPreferenceLocationAwareDisabled];
		[userDefaults removeObjectForKey:kOBAHiddenPreferenceSavedNavigationTargets];
		[userDefaults removeObjectForKey:kOBAHiddenPreferenceApplicationTerminationTimestamp];
		
		if( kIncludeUWActivityInferenceCode )
			[_activityLogger deleteAllTraces];
	}

	if( kIncludeUWUserStudyCode ) {
		_locationAware = ! [userDefaults boolForKey:kOBAHiddenPreferenceLocationAwareDisabled];
	}

	NSManagedObjectModel * managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	NSPersistentStoreCoordinator * persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: managedObjectModel] autorelease];
	
	NSURL *storeUrl = [NSURL fileURLWithPath: path];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	
	
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		
		OBALogSevereWithError(error,@"Error adding persistent store coordinator");
		
		if( ! [manager removeItemAtPath:path error:&error] ) {
			OBALogSevereWithError(error,@"Error deleting file: %@",path);
			return;
		}
		else {
			if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {				
				OBALogSevereWithError(error,@"Error adding persistent store coordinator (x2)");
				return;
			}
		}
	}
	
	_managedObjectContext = [[NSManagedObjectContext alloc] init];
	[_managedObjectContext setPersistentStoreCoordinator: persistentStoreCoordinator];
	
	_modelDao = [[OBAModelDAO alloc] initWithManagedObjectContext:_managedObjectContext];
	[_modelDao setup:&error];
	if( error ) {
		OBALogSevereWithError(error,@"Error on model dao setup");
		return;
	}
	
	[_activityListeners addListener:_modelDao];
	
	_modelFactory = [[OBAModelFactory alloc] initWithManagedObjectContext:_managedObjectContext];
	
	if( _locationAware )
		[_locationManager startUpdatingLocation];
	
	if( kIncludeUWActivityInferenceCode ) {
		[_activityLogger start];
		[_nearbyTripsController start];
	}
}

- (void) teardown {	
	if( kIncludeUWActivityInferenceCode ) {
		[_nearbyTripsController stop];
		[_activityLogger stop];
	}
	if( _locationAware )
		[_locationManager stopUpdatingLocation];
}	

- (void) saveApplicationNavigationState {

	UINavigationController * navController = (UINavigationController*) _tabBarController.selectedViewController;

	NSMutableArray * targets = [[NSMutableArray alloc] init];
	
	for( id source in [navController viewControllers] ) {
		if( ! [source conformsToProtocol:@protocol(OBANavigationTargetAware)] )
			break;
		id<OBANavigationTargetAware> targetSource = (id<OBANavigationTargetAware>) source;
		OBANavigationTarget * target = targetSource.navigationTarget;
		if( ! target )
			break;
		[targets addObject:target];
	}
	
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:targets];
	NSData *dateData = [NSKeyedArchiver archivedDataWithRootObject:[NSDate date]];
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:data forKey:kOBAHiddenPreferenceSavedNavigationTargets];
	[userDefaults setObject:dateData forKey:kOBAHiddenPreferenceApplicationTerminationTimestamp];
	if( kIncludeUWUserStudyCode )
		[userDefaults setBool:(!_locationAware) forKey:kOBAHiddenPreferenceLocationAwareDisabled];
	[targets release];	
}

- (void) restoreApplicationNavigationState {

	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSInteger showOnStartup = [userDefaults integerForKey:kOBAPreferenceShowOnStartup];

	if( 0 <= showOnStartup && showOnStartup < 4 )
		_tabBarController.selectedIndex = showOnStartup;

	// We only restore the application state if it's been less than x minutes
	// The idea is that, typically, if it's been more than x minutes, you've moved
	// on from the stop you were looking at, so we should just return to the home
	// screen
	NSData * dateData = [userDefaults objectForKey:kOBAHiddenPreferenceApplicationTerminationTimestamp];
	if( ! dateData ) 
		return;
	NSDate * date = [NSKeyedUnarchiver unarchiveObjectWithData:dateData];
	if( ! date || (-[date timeIntervalSinceNow]) > kMaxTimeSinceApplicationTerminationToRestoreState )
		return;
	
	NSData *data = [userDefaults objectForKey:kOBAHiddenPreferenceSavedNavigationTargets];
	
	if( ! data )
		return;
	
	NSArray * targets = [NSKeyedUnarchiver unarchiveObjectWithData:data];

	if( ! targets || [targets count] == 0)
		return;
	
	OBANavigationTarget * rootTarget = [targets objectAtIndex:0];
	
	switch(rootTarget.target) {
		case OBANavigationTargetTypeSearchResults:
			_tabBarController.selectedIndex = 0;
			break;
		case OBANavigationTargetTypeBookmarks:
			_tabBarController.selectedIndex = 1;
			break;
		case OBANavigationTargetTypeRecentStops:
			_tabBarController.selectedIndex = 2;
			break;
		case OBANavigationTargetTypeSearch:
			_tabBarController.selectedIndex = 3;
			break;
		case OBANavigationTargetTypeSettings:
			_tabBarController.selectedIndex = 4;
			break;
		default:
			return;
	}
	
	UINavigationController * rootNavController = (UINavigationController*) _tabBarController.selectedViewController;
	
	UIViewController * rootViewController = [rootNavController topViewController];
	
	[self setNavigationTarget:rootTarget forViewController:rootViewController];
	
	for( NSUInteger index = 1; index < [targets count]; index++) {
		OBANavigationTarget * nextTarget = [targets objectAtIndex:index];
		UIViewController * nextViewController = [self getViewControllerForTarget:nextTarget];
		if( ! nextViewController )
			break;		
		[self setNavigationTarget:nextTarget forViewController:nextViewController];
		[rootNavController pushViewController:nextViewController animated:TRUE];
		[nextViewController release];
	}
}

- (void) setNavigationTarget:(OBANavigationTarget*)target forViewController:(UIViewController*)viewController {
	if( ! [viewController conformsToProtocol:@protocol(OBANavigationTargetAware) ] )
		return;
	if( ! [viewController respondsToSelector:@selector(setNavigationTarget:) ] )
		return;
	id<OBANavigationTargetAware> targetAware = (id<OBANavigationTargetAware>) viewController;
	[targetAware setNavigationTarget:target];
}

- (UIViewController*) getViewControllerForTarget:(OBANavigationTarget*)target {
	
	switch(target.target) {
		case OBANavigationTargetTypeStop:
			return [[OBAStopViewController alloc] initWithApplicationContext:self];
		case OBANavigationTargetTypeActivityLogging:
			return [[OBAActivityLoggingViewController alloc] initWithApplicationContext:self];
		case OBANavigationTargetTypeActivityAnnotation:
			return [[OBAActivityAnnotationViewController alloc] initWithApplicationContext:self];
		case OBANavigationTargetTypeActivityUpload:
			return [[OBAUploadViewController alloc] initWithApplicationContext:self];
		case OBANavigationTargetTypeActivityLock:
			return [[OBALockViewController alloc] initWithApplicationContext:self];
	}
	
	return nil;
}

#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults {
	
	NSString * userId = [userDefaults stringForKey:kOBAHiddenPreferenceUserId];
	
	if( ! userId) {
		CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
		if (theUUID) {
			userId = NSMakeCollectable(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
			CFRelease(theUUID);
			[userDefaults setObject:userId forKey:kOBAHiddenPreferenceUserId];
		}
		else {
			userId = @"anonymous";
		}
	}
	
	return userId;
}

@end

