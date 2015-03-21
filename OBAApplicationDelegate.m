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

#import <SystemConfiguration/SystemConfiguration.h>
#import "OBAApplicationDelegate.h"
#import "OBANavigationTargetAware.h"
#import "OBALogger.h"

#import "OBASearchResultsMapViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBABookmarksViewController.h"
#import "OBAInfoViewController.h"

#import "OBASearchController.h"
#import "OBAStopViewController.h"
#import "OBAStopIconFactory.h"

#import "OBARegionListViewController.h"
#import "OBARegionHelper.h"
#import "OBAReleaseNotesManager.h"

#import "OBAAnalytics.h"

static NSString * kOBAHiddenPreferenceUserId = @"OBAApplicationUserId";
static NSString * kOBASelectedTabIndexDefaultsKey = @"OBASelectedTabIndexDefaultsKey";
static NSString * kOBAShowExperimentalRegionsDefaultsKey = @"kOBAShowExperimentalRegionsDefaultsKey";
static NSString * kOBADefaultRegionApiServerName = @"regions.onebusaway.org";
static NSString *const kTrackingId = @"UA-2423527-17";
static NSString *const kAllowTracking = @"allowTracking";
static NSString *kOBAShowSurveyAlertKey = @"OBASurveyAlertDefaultsKey";

@interface OBAApplicationDelegate ()
@property(nonatomic,readwrite) BOOL active;
@property(nonatomic) OBARegionHelper *regionHelper;
@end

@implementation OBAApplicationDelegate

- (id)init {
    self = [super init];

    if (self) {

        self.active = NO;

        _references = [[OBAReferencesV2 alloc] init];
        _modelDao = [[OBAModelDAO alloc] init];
        _locationManager = [[OBALocationManager alloc] initWithModelDao:_modelDao];        
                
        _modelService = [[OBAModelService alloc] init];
        _modelService.references = _references;
        _modelService.modelDao = _modelDao;
        
        OBAModelFactory * modelFactory = [[OBAModelFactory alloc] initWithReferences:_references];
        _modelService.modelFactory = modelFactory;
        
        _modelService.locationManager = _locationManager;
        
        _stopIconFactory = [[OBAStopIconFactory alloc] init];
        
        [self refreshSettings];
    }
    return self;
}


- (void) navigateToTarget:(OBANavigationTarget*)navigationTarget {
    [self performSelector:@selector(_navigateToTargetInternal:) withObject:navigationTarget afterDelay:0];
}

- (void)refreshSettings {
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * apiServerName = nil;
	if([self.modelDao.readCustomApiUrl isEqualToString:@""]) {
        if (_modelDao.region != nil) {
            apiServerName = [NSString stringWithFormat:@"%@", _modelDao.region.obaBaseUrl];
            // remove the last '/'
            apiServerName = [apiServerName substringToIndex:[apiServerName length]-1];
        }
        else {
            self.regionHelper = [[OBARegionHelper alloc] init];
            [self.modelDao writeSetRegionAutomatically:YES];
            [self.regionHelper updateNearestRegion];
            apiServerName = [NSString stringWithFormat:@"http://%@",apiServerName];
        }
        
    } else {
        apiServerName = [NSString stringWithFormat:@"http://%@",self.modelDao.readCustomApiUrl];
        if ([apiServerName hasSuffix:@"/"]) {
            apiServerName = [apiServerName substringToIndex:[apiServerName length]-1];
        }
    }
    
    NSString * userId = [self userIdFromDefaults:userDefaults];
    NSString * appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * obaArgs = [NSString stringWithFormat:@"key=org.onebusaway.iphone&app_uid=%@&app_ver=%@",userId,appVersion];
    
    OBADataSourceConfig * obaDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:apiServerName args:obaArgs];    
    OBAJsonDataSource * obaJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:obaDataSourceConfig];
    _modelService.obaJsonDataSource = obaJsonDataSource;
    
    OBADataSourceConfig * googleMapsDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:@"https://maps.googleapis.com" args:@"&sensor=true"];
    OBAJsonDataSource * googleMapsJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:googleMapsDataSourceConfig];
    _modelService.googleMapsJsonDataSource = googleMapsJsonDataSource;
    
    
    NSString * regionApiServerName = [userDefaults objectForKey:@"oba_region_api_server"];
    if (regionApiServerName == nil || [regionApiServerName length] == 0) {
        regionApiServerName = kOBADefaultRegionApiServerName;
    }
    
    regionApiServerName = [NSString stringWithFormat:@"http://%@", regionApiServerName];
    
    OBADataSourceConfig * obaRegionDataSourceConfig = [[OBADataSourceConfig alloc] initWithUrl:regionApiServerName args:obaArgs];
    OBAJsonDataSource * obaRegionJsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:obaRegionDataSourceConfig];
    _modelService.obaRegionJsonDataSource = obaRegionJsonDataSource;
    
    [userDefaults setObject:appVersion forKey:@"oba_application_version"];
}

- (void)_constructUI
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];

    self.tabBarController = [[UITabBarController alloc] init];

    self.mapViewController = [[OBASearchResultsMapViewController alloc] init];
    self.mapViewController.appDelegate = self;
    self.mapNavigationController = [[UINavigationController alloc] initWithRootViewController:self.mapViewController];
    
    self.recentsViewController = [[OBARecentStopsViewController alloc] init];
    self.recentsViewController.appDelegate = self;
    self.recentsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.recentsViewController];

    self.bookmarksViewController = [[OBABookmarksViewController alloc] init];
    self.bookmarksViewController.appDelegate = self;
    self.bookmarksNavigationController = [[UINavigationController alloc] initWithRootViewController:self.bookmarksViewController];
    
    self.infoViewController = [[OBAInfoViewController alloc] init];
    self.infoNavigationController = [[UINavigationController alloc] initWithRootViewController:self.infoViewController];

    self.tabBarController.viewControllers = @[self.mapNavigationController, self.recentsNavigationController, self.bookmarksNavigationController, self.infoNavigationController];
    self.tabBarController.delegate = self;

    [self _updateSelectedTabIndex];
    
    UIColor *tintColor = OBAGREEN;
    [[UINavigationBar appearance] setTintColor:tintColor];
    [[UISearchBar appearance] setTintColor:tintColor];
    [[UISegmentedControl appearance] setTintColor:tintColor];
    [[UITabBar appearance] setSelectedImageTintColor:tintColor];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        [[UITabBar appearance] setTintColor:tintColor];
        [[UITextField appearance] setTintColor:tintColor];
        [[UISegmentedControl appearance] setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]} forState:UIControlStateNormal];
        [[UISegmentedControl appearance] setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]} forState:UIControlStateSelected];
    }
    
    self.window.rootViewController = self.tabBarController;
    
    if ([self.modelDao.readCustomApiUrl isEqualToString:@""]) {
        _regionHelper = [[OBARegionHelper alloc] init];
        if (self.modelDao.readSetRegionAutomatically && self.locationManager.locationServicesEnabled) {
            [_regionHelper updateNearestRegion];
        } else {
            [_regionHelper updateRegion];
        }
    }

    [self.window makeKeyAndVisible];

    if ([OBAReleaseNotesManager shouldShowReleaseNotes]) {
        [OBAReleaseNotesManager showReleaseNotes:self.window];
    }
}

#pragma mark UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    //Register alert defaults
    NSDictionary *alertDefaults = @{kOBAShowSurveyAlertKey: @(YES)};
    [[NSUserDefaults standardUserDefaults] registerDefaults:alertDefaults];

    //setup Google Analytics
    NSDictionary *appDefaults = @{kAllowTracking: @(YES)};
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];

    // User must be able to opt out of tracking
    [GAI sharedInstance].optOut = ![[NSUserDefaults standardUserDefaults] boolForKey:kAllowTracking];

    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];

    //don't report to Google Analytics when developing
#ifdef DEBUG
    [[GAI sharedInstance] setDryRun:YES];
#endif

    self.tracker = [[GAI sharedInstance] trackerWithTrackingId:kTrackingId];

    [self _constructUI];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    CLLocation * location = _locationManager.currentLocation;
    if ( location )
    {
        _modelDao.mostRecentLocation = location;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self applicationDidEnterBackground:application]; // call for iOS < 4.0 devices
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    self.active = YES;
    self.tabBarController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kOBASelectedTabIndexDefaultsKey];
    [GAI sharedInstance].optOut =
    ![[NSUserDefaults standardUserDefaults] boolForKey:kAllowTracking];

    if([self.modelDao.readCustomApiUrl isEqualToString:@""]) {
        [OBAAnalytics reportEventWithCategory:@"app_settings" action:@"configured_region" label:[NSString stringWithFormat:@"API Region: %@",self.modelDao.region.regionName] value:nil];
    }else{
        [OBAAnalytics reportEventWithCategory:@"app_settings" action:@"configured_region" label:@"API Region: Custom URL" value:nil];
    }
    [OBAAnalytics reportEventWithCategory:@"app_settings" action:@"general" label:[NSString stringWithFormat:@"Set Region Automatically: %@", (self.modelDao.readSetRegionAutomatically ? @"YES" : @"NO")] value:nil];

    BOOL _showExperimentalRegions = NO;
    if ([[NSUserDefaults standardUserDefaults] boolForKey: @"kOBAShowExperimentalRegionsDefaultsKey"])
        _showExperimentalRegions = [[NSUserDefaults standardUserDefaults] boolForKey: @"kOBAShowExperimentalRegionsDefaultsKey"];
    [OBAAnalytics reportEventWithCategory:@"app_settings" action:@"general" label:[NSString stringWithFormat:@"Show Experimental Regions: %@", (_showExperimentalRegions ? @"YES" : @"NO")] value:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    self.active = NO;
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSUInteger oldIndex = [self.tabBarController.viewControllers indexOfObject:[self.tabBarController selectedViewController]];
    NSUInteger newIndex = [self.tabBarController.viewControllers indexOfObject:viewController];
    if(newIndex == 0 && newIndex == oldIndex) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OBAMapButtonRecenterNotification" object:nil];
    }

    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [[NSUserDefaults standardUserDefaults] setInteger:tabBarController.selectedIndex forKey:kOBASelectedTabIndexDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)_updateSelectedTabIndex {
    NSInteger selectedIndex = 0;
    NSString * startupView = nil;

    if ([[NSUserDefaults standardUserDefaults] objectForKey:kOBASelectedTabIndexDefaultsKey]) {
        selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kOBASelectedTabIndexDefaultsKey];
    }
    self.tabBarController.selectedIndex = selectedIndex;

    switch (selectedIndex) {
        case 0:
            startupView = @"OBASearchResultsMapViewController";
            break;
        case 1:
            startupView = @"OBARecentStopsViewController";
            break;
        case 2:
            startupView = @"OBABookmarksViewController";
            break;
        case 3:
            startupView = @"OBAInfoViewController";
            break;
        default:
            startupView = @"Unknown";
            break;
    }

    [OBAAnalytics reportEventWithCategory:@"app_settings" action:@"startup" label:[NSString stringWithFormat:@"Startup View: %@",startupView] value:nil];
}

- (void) _navigateToTargetInternal:(OBANavigationTarget*)navigationTarget {
    
    [_references clear];
    
    [self.mapNavigationController popToRootViewControllerAnimated:NO];
    
    if (OBANavigationTargetTypeSearchResults == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.mapNavigationController];
        self.mapViewController.navigationTarget = navigationTarget;
    }
    else if (OBANavigationTargetTypeContactUs == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.infoNavigationController];
        [self.infoViewController openContactUs];
    }
    else if (OBANavigationTargetTypeSettings == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.infoNavigationController];
        [self.infoViewController openSettings];
    }
    else if (OBANavigationTargetTypeAgencies == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.infoNavigationController];
        [self.infoViewController openAgencies];
    }
    else if (OBANavigationTargetTypeBookmarks == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.bookmarksNavigationController];
    }
    else {
        NSLog(@"Unhandled target in %s: %@", __PRETTY_FUNCTION__, @(navigationTarget.target));
    }
}

- (NSString *)userIdFromDefaults:(NSUserDefaults*)userDefaults {
    
    NSString * userId = [userDefaults stringForKey:kOBAHiddenPreferenceUserId];
    
    if( ! userId) {
        CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
        if (theUUID) {
            userId = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
            CFRelease(theUUID);
            [userDefaults setObject:userId forKey:kOBAHiddenPreferenceUserId];
            [userDefaults synchronize];
        }
        else {
            userId = @"anonymous";
        }
    }
    
    return userId;
}

- (void)regionSelected {
    [_regionNavigationController removeFromParentViewController];
    _regionNavigationController = nil;
    _regionListViewController = nil;
    
    [self refreshSettings];
    
    self.window.rootViewController = self.tabBarController;
    [_window makeKeyAndVisible];
}

- (void) showRegionListViewController
{
    _regionListViewController = [[OBARegionListViewController alloc] initWithApplicationDelegate:self];
    _regionNavigationController = [[UINavigationController alloc] initWithRootViewController:_regionListViewController];

    self.window.rootViewController = _regionNavigationController;
}

@end

