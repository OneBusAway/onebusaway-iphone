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

#import "OBAApplicationContext.h"
#import "OBAViewContext.h"
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


static NSString * kOBASavedNavigationTargets = @"OBASavedNavigationTargets";
static NSString * kOBAApplicationTerminationTimestamp = @"OBAApplicationTerminationTimestamp";
static const double kMaxTimeSinceApplicationTerminationToRestoreState = 1*60;

@interface OBAApplicationContext (Private)

- (void) setup:(NSError**)error;
- (void) teardown;

- (void) saveApplicationNavigationState;
- (void) restoreApplicationNavigationState;

- (void) setNavigationTarget:(OBANavigationTarget*)target forViewController:(UIViewController*)viewController;
- (UIViewController*) getViewControllerForTarget:(OBANavigationTarget*)target;

- (NSString *)applicationDocumentsDirectory;

@end


@implementation OBAApplicationContext

@synthesize modelDao = _modelDao;
@synthesize modelFactory = _modelFactory;
@synthesize locationManager = _locationManager;
@synthesize activityListeners = _activityListeners;

@synthesize obaDataSourceConfig = _obaDataSourceConfig;
@synthesize googleMapsDataSourceConfig = _googleMapsDataSourceConfig;

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

- (id) init {
	if( self = [super init] ) {
		_obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://api.onebusaway.org" args:@"key=org.onebusaway.iphone"];
		//_jsonDataSource = [[OBAJsonDataSource alloc] initWithBaseUrl:@"http://beta.onebusaway.org" withBaseArgs:@"key=org.onebusaway.iphone"];
		//_jsonDataSource = [[OBAJsonDataSource alloc] initWithBaseUrl:@"http://localhost:8080/org.onebusaway" withBaseArgs:@"key=org.onebusaway.iphone"];
		
		_googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"http://maps.google.com" args:@"output=json&oe=utf-8&key=ABQIAAAA1R_R0bUhLYRwbQFpKHVowhRAXGY6QyK0faTs-0G7h9EE_iri4RRtKgRdKFvvraEP5PX_lP_RlqKkzA"];
		
		_locationManager = [[OBALocationManager alloc] init];
		
		_activityListeners = [[OBAActivityListeners alloc] init];		
		
		if( kIncludeUWActivityInferenceCode ) {
			_activityLogger = [[OBAActivityLogger alloc] init];
			_activityLogger.context = self;
		}
	}
	return self;
}

- (void) dealloc {
	
	[_managedObjectContext release];
	[_modelDao release];
	
	[_locationManager release];
	[_activityListeners release];
	
	[_obaDataSourceConfig release];
	[_googleMapsDataSourceConfig release];
	
	if( kIncludeUWActivityInferenceCode )
		[_activityLogger release];
	
	[_window release];
	[_tabBarController release];
	[_searchResultsMapViewController release];
	
	[super dealloc];
}

- (void) navigateToTarget:(OBANavigationTarget*)navigationTarget {
	
	switch (navigationTarget.target) {
		case OBANavigationTargetTypeSearchResults:
			[_searchResultsMapViewController searchWithTarget:navigationTarget];
			_tabBarController.selectedIndex = 0;
			break;
	}
}

#pragma mark UIApplicationDelegate Methods

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	
	NSError * error = nil;
	[self setup:&error];
	if( error ) {
		NSLog(@"Bad!");
	}
	
	_searchResultsMapViewController = [[OBASearchResultsMapViewController alloc] initWithApplicationContext:self];
	UINavigationController * mapNav = [[UINavigationController alloc] initWithRootViewController:_searchResultsMapViewController];
	mapNav.tabBarItem.title = @"Map";
	mapNav.tabBarItem.image = [UIImage imageNamed:@"CrossHairs.png"];
	
	OBABookmarksViewController * bookmarksViewController = [[OBABookmarksViewController alloc] initWithApplicationContext:self];
	UINavigationController * bookmarksNav = [[UINavigationController alloc] initWithRootViewController:bookmarksViewController];
	bookmarksNav.tabBarItem.title = @"Bookmarks";
	bookmarksNav.tabBarItem.image = [UIImage imageNamed:@"Bookmarks.png"];
	
	OBARecentStopsViewController * recentStopsViewController = [[OBARecentStopsViewController alloc] initWithApplicationContext:self];
	UINavigationController * recentStopsNav = [[UINavigationController alloc] initWithRootViewController:recentStopsViewController];
	recentStopsNav.tabBarItem.title = @"Recent";
	recentStopsNav.tabBarItem.image = [UIImage imageNamed:@"Clock.png"];
	
	OBASearchViewController * searchViewController = [[OBASearchViewController alloc] initWithApplicationContext:self];
	UINavigationController * searchNav = [[UINavigationController alloc] initWithRootViewController:searchViewController];
	searchNav.tabBarItem.title = @"Search";
	searchNav.tabBarItem.image = [UIImage imageNamed:@"MagnifyingGlass.png"];
	
	OBASettingsViewController * settingsViewController = [[OBASettingsViewController alloc] initWithApplicationContext:self];
	UINavigationController * settingsNav = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
	settingsNav.tabBarItem.title = @"Settings";
	settingsNav.tabBarItem.image = [UIImage imageNamed:@"Gear.png"];
	
	NSArray * viewControllers = [NSArray arrayWithObjects: mapNav, bookmarksNav, recentStopsNav, searchNav, settingsNav, nil];
	[_tabBarController setViewControllers:viewControllers animated:TRUE];
	
	[bookmarksViewController release];
	
	UIView * rootView = [_tabBarController view];
	[_window addSubview:rootView];
	[_window makeKeyWindow];
	
	OBANavigationTarget * navTarget = [OBASearchControllerFactory getNavigationTargetForSearchCurrentLocation];
	[self navigateToTarget:navTarget];
	
	[self restoreApplicationNavigationState];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	NSLog(@"Application: Terminate!");
	
	[self saveApplicationNavigationState];	
	[self teardown];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	NSLog(@"Application: Active!");	
}

- (void)applicationWillResignActive:(UIApplication *)application {
	NSLog(@"Application: IN-Active!");		
}

@end

@implementation OBAApplicationContext (Private)

- (void) setup:(NSError**)error {
	
	NSManagedObjectModel * managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	NSPersistentStoreCoordinator * persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: managedObjectModel] autorelease];
	
	NSString * path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"OneBusAway.sqlite"];
	NSURL *storeUrl = [NSURL fileURLWithPath: path];
	NSFileManager * manager = [NSFileManager defaultManager];
	
	// Delete model on startup?
	if( TRUE ) {
		if( ! [manager removeItemAtPath:path error:error] ) {
			OBALogSevereWithError(*error,@"Error deleting file: %@",path);
			return;
		}	
	}
	
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:error]) {
		
		OBALogSevereWithError(*error,@"Error adding persistent store coordinator");
		
		if( ! [manager removeItemAtPath:path error:error] ) {
			OBALogSevereWithError(*error,@"Error deleting file: %@",path);
			return;
		}
		else {
			if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:error]) {				
				OBALogSevereWithError(*error,@"Error adding persistent store coordinator (x2)");
				return;
			}
		}
	}
	
	_managedObjectContext = [[NSManagedObjectContext alloc] init];
	[_managedObjectContext setPersistentStoreCoordinator: persistentStoreCoordinator];
	
	_modelDao = [[OBAModelDAO alloc] initWithManagedObjectContext:_managedObjectContext];
	[_modelDao setup:error];
	if( *error )
		return;
	
	[_activityListeners addListener:_modelDao];
	
	_modelFactory = [[OBAModelFactory alloc] initWithManagedObjectContext:_managedObjectContext];
	
	[_locationManager startUpdatingLocation];
	
	if( kIncludeUWActivityInferenceCode )
		[_activityLogger start];
}

- (void) teardown {	
	if( kIncludeUWActivityInferenceCode )
		[_activityLogger stop];
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
	[userDefaults setObject:data forKey:kOBASavedNavigationTargets];
	[userDefaults setObject:dateData forKey:kOBAApplicationTerminationTimestamp];
	[targets release];	
}

- (void) restoreApplicationNavigationState {

	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	// We only restore the application state if it's been less than x minutes
	// The idea is that, typically, if it's been more than x minutes, you've moved
	// on from the stop you were looking at, so we should just return to the home
	// screen
	NSData * dateData = [userDefaults objectForKey:kOBAApplicationTerminationTimestamp];
	if( ! dateData ) 
		return;
	NSDate * date = [NSKeyedUnarchiver unarchiveObjectWithData:dateData];
	if( ! date || (-[date timeIntervalSinceNow]) > kMaxTimeSinceApplicationTerminationToRestoreState )
		return;
	
	NSData *data = [userDefaults objectForKey:kOBASavedNavigationTargets];
	
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
			return [[[OBAStopViewController alloc] initWithApplicationContext:self] autorelease];
		case OBANavigationTargetTypeActivityLogging:
			return [[[OBAActivityLoggingViewController alloc] initWithApplicationContext:self] autorelease];
		case OBANavigationTargetTypeActivityAnnotation:
			return [[[OBAActivityAnnotationViewController alloc] initWithApplicationContext:self] autorelease];
		case OBANavigationTargetTypeActivityUpload:
			return [[[OBAUploadViewController alloc] initWithApplicationContext:self] autorelease];
		case OBANavigationTargetTypeActivityLock:
			return [[[OBALockViewController alloc] initWithApplicationContext:self] autorelease];
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

@end

