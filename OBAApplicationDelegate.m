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
#import <ABReleaseNotesViewController/ABReleaseNotesViewController.h>
#import "OBAApplicationDelegate.h"
#import "OBANavigationTargetAware.h"
#import "OBALogger.h"

#import "OBASearchResultsMapViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBABookmarksViewController.h"
#import "OBAInfoViewController.h"

#import "OBASearchController.h"
#import "OBAStopViewController.h"

#import "OBARegionListViewController.h"
#import "OBARegionHelper.h"

#import "OBAAnalytics.h"
#import "NSArray+OBAAdditions.h"

static NSString *kOBASelectedTabIndexDefaultsKey = @"OBASelectedTabIndexDefaultsKey";
static NSString *kOBAShowExperimentalRegionsDefaultsKey = @"kOBAShowExperimentalRegionsDefaultsKey";
static NSString *const kTrackingId = @"UA-2423527-17";
static NSString *const kAllowTracking = @"allowTracking";

static NSString *const kApplicationShortcutMap = @"org.onebusaway.iphone.shortcut.map";
static NSString *const kApplicationShortcutRecents = @"org.onebusaway.iphone.shortcut.recents";
static NSString *const kApplicationShortcutBookmarks = @"org.onebusaway.iphone.shortcut.bookmarks";

@interface OBAApplicationDelegate () <OBABackgroundTaskExecutor>
@property (nonatomic, readwrite) BOOL active;
@property (nonatomic, strong) OBARegionHelper *regionHelper;
@property (nonatomic, strong) id regionObserver;
@property (nonatomic, strong) id recentStopsObserver;
@property(nonatomic,strong) ABReleaseNotesViewController *releaseNotes;
@end

@implementation OBAApplicationDelegate

- (id)init {
    self = [super init];

    if (self) {
        _active = NO;
        _regionHelper = [[OBARegionHelper alloc] init];

        @weakify(self);
        self.regionObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kOBAApplicationSettingsRegionRefreshNotification
                                                                                object:nil
                                                                                 queue:[NSOperationQueue mainQueue]
                                                                            usingBlock:^(NSNotification *note) {
                                                                                @strongify(self);
                                                                                [self writeSetRegionAutomatically:YES];
                                                                                [self.regionHelper updateNearestRegion];
                                                                            }];
        self.recentStopsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:OBAMostRecentStopsChangedNotification
                                                                                     object:nil
                                                                                      queue:[NSOperationQueue mainQueue]
                                                                                 usingBlock:^(NSNotification *note) {
                                                                                     @strongify(self);
                                                                                     [self updateShortcutItemsForRecentStops];
                                                                                 }];
        
        [[OBAApplication sharedApplication] start];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.regionObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.recentStopsObserver];
}

- (void)writeSetRegionAutomatically:(BOOL)setRegionAutomatically {
    [[OBAApplication sharedApplication].modelDao writeSetRegionAutomatically:setRegionAutomatically];
    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:2] value:(setRegionAutomatically ? @"YES" : @"NO")];
}

- (BOOL)readSetRegionAutomatically {
    BOOL readSetRegionAuto = [OBAApplication sharedApplication].modelDao.readSetRegionAutomatically;

    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:2] value:(readSetRegionAuto ? @"YES" : @"NO")];
    return readSetRegionAuto;
}

- (void)setOBARegion:(OBARegionV2 *)region {
    [[OBAApplication sharedApplication].modelDao setOBARegion:region];
    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:1] value:region.regionName];
}

- (void)navigateToTarget:(OBANavigationTarget *)navigationTarget {
    [self performSelector:@selector(_navigateToTargetInternal:) withObject:navigationTarget afterDelay:0];
}

- (void)_constructUI {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor blackColor];

    self.tabBarController = [[UITabBarController alloc] init];

    self.mapViewController = [[OBASearchResultsMapViewController alloc] init];
    self.mapViewController.appDelegate = self;
    self.mapNavigationController = [[UINavigationController alloc] initWithRootViewController:self.mapViewController];

    self.recentsViewController = [[OBARecentStopsViewController alloc] init];
    self.recentsNavigationController = [[UINavigationController alloc] initWithRootViewController:self.recentsViewController];

    self.bookmarksViewController = [[OBABookmarksViewController alloc] init];
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
    [[UITabBar appearance] setTintColor:tintColor];
    [[UITextField appearance] setTintColor:tintColor];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] } forState:UIControlStateSelected];

    self.window.rootViewController = self.tabBarController;

    if ([[OBAApplication sharedApplication].modelDao.readCustomApiUrl isEqualToString:@""]) {
        if ([OBAApplication sharedApplication].modelDao.readSetRegionAutomatically && [OBAApplication sharedApplication].locationManager.locationServicesEnabled) {
            [self.regionHelper updateNearestRegion];
        }
        else {
            [self.regionHelper updateRegion];
        }
    }

    [self.window makeKeyAndVisible];

    self.releaseNotes = [[ABReleaseNotesViewController alloc] initWithAppIdentifier:@"329380089"];
    self.releaseNotes.title = NSLocalizedString(@"What's New", @"");
    self.releaseNotes.mode = ABReleaseNotesViewControllerModeProduction;

    [self.releaseNotes checkForUpdates:^(BOOL updated) {
        if (updated) {
            [self.tabBarController presentViewController:self.releaseNotes animated:YES completion:nil];
        }
    }];
}

#pragma mark - UIApplication Methods

- (UIBackgroundTaskIdentifier)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    return [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:handler];
}

- (UIBackgroundTaskIdentifier)endBackgroundTask:(UIBackgroundTaskIdentifier)task {
    [[UIApplication sharedApplication] endBackgroundTask:task];
    return UIBackgroundTaskInvalid;
}

#pragma mark UIApplicationDelegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //Register a background handler with the model service
    [OBAModelService addBackgroundExecutor:self];

    //setup Google Analytics
    NSDictionary *appDefaults = @{ kAllowTracking: @(YES) };
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];

    // User must be able to opt out of tracking
    [GAI sharedInstance].optOut = ![[NSUserDefaults standardUserDefaults] boolForKey:kAllowTracking];

    [GAI sharedInstance].trackUncaughtExceptions = YES;
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelWarning];

    //don't report to Google Analytics when developing
#ifdef DEBUG
    [[GAI sharedInstance] setDryRun:YES];
#endif

    self.tracker = [[GAI sharedInstance] trackerWithTrackingId:kTrackingId];

    [[GAI sharedInstance].defaultTracker set:[GAIFields customDimensionForIndex:1] value:[OBAApplication sharedApplication].modelDao.region.regionName];

    [OBAAnalytics configureVoiceOverStatus];

    [self _constructUI];

    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    CLLocation *location = [OBAApplication sharedApplication].locationManager.currentLocation;

    if (location) {
        [OBAApplication sharedApplication].modelDao.mostRecentLocation = location;
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

    if ([[OBAApplication sharedApplication].modelDao.readCustomApiUrl isEqualToString:@""]) {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"configured_region" label:[NSString stringWithFormat:@"API Region: %@", [OBAApplication sharedApplication].modelDao.region.regionName] value:nil];
    }
    else {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"configured_region" label:@"API Region: Custom URL" value:nil];
    }

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"general" label:[NSString stringWithFormat:@"Set Region Automatically: %@", ([OBAApplication sharedApplication].modelDao.readSetRegionAutomatically ? @"YES" : @"NO")] value:nil];

    BOOL _showExperimentalRegions = NO;

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"kOBAShowExperimentalRegionsDefaultsKey"]) _showExperimentalRegions = [[NSUserDefaults standardUserDefaults] boolForKey:@"kOBAShowExperimentalRegionsDefaultsKey"];

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"general" label:[NSString stringWithFormat:@"Show Experimental Regions: %@", (_showExperimentalRegions ? @"YES" : @"NO")] value:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    self.active = NO;
}

#pragma mark Shortcut Items

- (void)application:(UIApplication *)application performActionForShortcutItem:(nonnull UIApplicationShortcutItem *)shortcutItem completionHandler:(nonnull void (^)(BOOL))completionHandler {
    NSString *shortcutIdentifier = shortcutItem.type;

    if ([shortcutIdentifier isEqualToString:kApplicationShortcutMap]) {
        [self.tabBarController setSelectedViewController:self.mapNavigationController];

        [self.mapNavigationController popToRootViewControllerAnimated:NO];
        [self.mapViewController onCrossHairsButton:self];
    } else if ([shortcutIdentifier isEqualToString:kApplicationShortcutBookmarks]) {
        [self.tabBarController setSelectedViewController:self.bookmarksNavigationController];

        [self.bookmarksNavigationController popToRootViewControllerAnimated:NO];
    } else if ([shortcutIdentifier isEqualToString:kApplicationShortcutRecents]) {
        [self.tabBarController setSelectedViewController:self.recentsNavigationController];

        NSArray *stopIds = (NSArray *)shortcutItem.userInfo[@"stopIds"];
        if (stopIds.count > 0) {
            UIViewController *vc = [OBAStopViewController stopControllerWithStopID:stopIds[0]];
            [self.recentsNavigationController popToRootViewControllerAnimated:NO];
            [self.recentsNavigationController pushViewController:vc animated:YES];
        }
    }

    // update kOBASelectedTabIndexDefaultsKey, since the delegate doesn't fire
    // otherwise applicationDidBecomeActive: will switch us away
    [self tabBarController:self.tabBarController didSelectViewController:self.tabBarController.selectedViewController];

    completionHandler(YES);
}

- (void)updateShortcutItemsForRecentStops {
    NSMutableArray *dynamicShortcuts = [NSMutableArray array];
    UIApplicationShortcutIcon *clockIcon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeTime];

    for (OBAStopAccessEventV2 *stopEvent in [OBAApplication sharedApplication].modelDao.mostRecentStops) {
        UIApplicationShortcutItem *shortcutItem =
                [[UIApplicationShortcutItem alloc] initWithType:kApplicationShortcutRecents
                                                 localizedTitle:stopEvent.title
                                              localizedSubtitle:nil
                                                           icon:clockIcon
                                                       userInfo:@{ @"stopIds": stopEvent.stopIds }];
        [dynamicShortcuts addObject:shortcutItem];
    }

    [UIApplication sharedApplication].shortcutItems = [dynamicShortcuts oba_pickFirst:4];
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSUInteger oldIndex = [self.tabBarController.viewControllers indexOfObject:[self.tabBarController selectedViewController]];
    NSUInteger newIndex = [self.tabBarController.viewControllers indexOfObject:viewController];

    if (newIndex == 0 && newIndex == oldIndex) {
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
    NSString *startupView = nil;

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

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"startup" label:[NSString stringWithFormat:@"Startup View: %@", startupView] value:nil];
}

- (void)_navigateToTargetInternal:(OBANavigationTarget *)navigationTarget {
    [[OBAApplication sharedApplication].references clear];

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

- (void)regionSelected {
    [_regionNavigationController removeFromParentViewController];
    _regionNavigationController = nil;
    _regionListViewController = nil;

    [[OBAApplication sharedApplication] refreshSettings];

    self.window.rootViewController = self.tabBarController;
    [_window makeKeyAndVisible];
}

- (void)showRegionListViewController {
    _regionListViewController = [[OBARegionListViewController alloc] init];
    _regionNavigationController = [[UINavigationController alloc] initWithRootViewController:_regionListViewController];

    self.window.rootViewController = _regionNavigationController;
}

@end
