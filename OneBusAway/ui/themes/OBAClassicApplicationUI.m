//
//  OBAClassicApplicationUI.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAClassicApplicationUI.h"
@import OBAKit;
#import "OBAMapViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBABookmarksViewController.h"
#import "OBAInfoViewController.h"
#import "OBAStopViewController.h"
#import "OBAAnalytics.h"
#import "OneBusAway-Swift.h"

static NSString *kOBASelectedTabIndexDefaultsKey = @"OBASelectedTabIndexDefaultsKey";

@interface OBAClassicApplicationUI ()<UITabBarControllerDelegate>
@property(nonatomic, strong,readwrite) UITabBarController *tabBarController;

@property(nonatomic,strong) NearbyStopsViewController *nearbyStopsController;
@property(nonatomic,strong) UINavigationController *nearbyStopsNavigation;

@property(nonatomic, strong) UINavigationController *mapNavigationController;
@property(strong) OBAMapViewController *mapViewController;

@property(strong) UINavigationController *recentsNavigationController;
@property(strong) OBARecentStopsViewController *recentsViewController;

@property(strong) UINavigationController *bookmarksNavigationController;
@property(strong) OBABookmarksViewController *bookmarksViewController;

@property(strong) UINavigationController *infoNavigationController;
@property(strong) OBAInfoViewController *infoViewController;
@end

@implementation OBAClassicApplicationUI

- (instancetype)initWithApplication:(OBAApplication*)application {

    self = [super init];

    if (self) {
        _tabBarController = [[UITabBarController alloc] init];

        _mapViewController = [[OBAMapViewController alloc] initWithMapDataLoader:application.mapDataLoader mapRegionManager:application.mapRegionManager];
        _mapNavigationController = [[UINavigationController alloc] initWithRootViewController:_mapViewController];

        _recentsViewController = [[OBARecentStopsViewController alloc] init];
        _recentsNavigationController = [[UINavigationController alloc] initWithRootViewController:_recentsViewController];

        _bookmarksViewController = [[OBABookmarksViewController alloc] init];
        _bookmarksNavigationController = [[UINavigationController alloc] initWithRootViewController:_bookmarksViewController];

        _infoViewController = [[OBAInfoViewController alloc] init];
        _infoNavigationController = [[UINavigationController alloc] initWithRootViewController:_infoViewController];

        _tabBarController.viewControllers = @[_mapNavigationController, _recentsNavigationController, _bookmarksNavigationController, _infoNavigationController];
        _tabBarController.delegate = self;
    }

    return self;
}

#pragma mark - Public Methods

- (UIViewController*)rootViewController {
    return self.tabBarController;
}

- (void)performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    NSDictionary *parameters = nil;
    OBANavigationTargetType navigationTargetType = OBANavigationTargetTypeUndefined;

    if ([shortcutItem.type isEqual:kApplicationShortcutMap]) {
        navigationTargetType = OBANavigationTargetTypeMap;
    }
    else if ([shortcutItem.type isEqual:kApplicationShortcutBookmarks]) {
        navigationTargetType = OBANavigationTargetTypeBookmarks;
    }
    else if ([shortcutItem.type isEqual:kApplicationShortcutRecents]) {
        navigationTargetType = OBANavigationTargetTypeRecentStops;
        NSString *stopID = (NSString*)shortcutItem.userInfo[@"stopID"];
        if (stopID.length > 0) {
            parameters = @{OBAStopIDNavigationTargetParameter: stopID};
        }
    }

    OBANavigationTarget *navigationTarget = [OBANavigationTarget navigationTarget:navigationTargetType parameters:parameters];
    [self navigateToTargetInternal:navigationTarget];

    completionHandler(YES);
}

- (void)applicationDidBecomeActive {
    [self updateSelectedTabIndex];
}

- (void)updateSelectedTabIndex {
    NSInteger selectedIndex = 0;
    NSString *startingTab = nil;

    if ([OBAApplication.sharedApplication.userDefaults objectForKey:kOBASelectedTabIndexDefaultsKey]) {
        selectedIndex = [OBAApplication.sharedApplication.userDefaults integerForKey:kOBASelectedTabIndexDefaultsKey];
    }

    self.tabBarController.selectedIndex = selectedIndex;

    switch (selectedIndex) {
        case 0:
            startingTab = @"OBAMapViewController";
            break;

        case 1:
            startingTab = @"OBARecentStopsViewController";
            break;

        case 2:
            startingTab = @"OBABookmarksViewController";
            break;

        case 3:
            startingTab = @"OBAInfoViewController";
            break;

        default:
            startingTab = @"Unknown";
            break;
    }

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAppSettings action:@"startup" label:[NSString stringWithFormat:@"Startup View: %@", startingTab] value:nil];
}

- (void)navigateToTargetInternal:(OBANavigationTarget*)navigationTarget {
    [self.mapNavigationController popToRootViewControllerAnimated:NO];

    UIViewController<OBANavigationTargetAware> *viewController = nil;

    switch (navigationTarget.target) {
        case OBANavigationTargetTypeMap: {
            [self.tabBarController setSelectedViewController:self.mapNavigationController];
            viewController = self.mapViewController;
            break;
        }

        case OBANavigationTargetTypeSearchResults: {
            [self.tabBarController setSelectedViewController:self.mapNavigationController];
            viewController = self.mapViewController;
            break;
        }

        case OBANavigationTargetTypeRecentStops: {
            self.tabBarController.selectedViewController = self.recentsNavigationController;
            viewController = self.recentsViewController;
            break;
        }

        case OBANavigationTargetTypeBookmarks: {
            self.tabBarController.selectedViewController = self.bookmarksNavigationController;
            viewController = self.bookmarksViewController;
            break;
        }

        case OBANavigationTargetTypeContactUs: {
            [self.tabBarController setSelectedViewController:self.infoNavigationController];
            viewController = self.infoViewController;
            break;
        }

        case OBANavigationTargetTypeUndefined:
        default: {
            DDLogError(@"Unhandled target in %s: %@", __PRETTY_FUNCTION__, @(navigationTarget.target));
        }
    }

    if ([viewController respondsToSelector:@selector(setNavigationTarget:)]) {
        [viewController setNavigationTarget:navigationTarget];
    }

    if (navigationTarget.parameters[@"stop"]) {
        OBAStopViewController *vc = [[OBAStopViewController alloc] initWithStopID:navigationTarget.parameters[@"stopID"]];
        [self.mapNavigationController pushViewController:vc animated:YES];
    }

    // update kOBASelectedTabIndexDefaultsKey, otherwise -applicationDidBecomeActive: will switch us away.
    [self tabBarController:self.tabBarController didSelectViewController:self.tabBarController.selectedViewController];
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSUInteger oldIndex = [self.tabBarController.viewControllers indexOfObject:[self.tabBarController selectedViewController]];
    NSUInteger newIndex = [self.tabBarController.viewControllers indexOfObject:viewController];

    if (newIndex == 0 && newIndex == oldIndex) {
        [self.mapViewController recenterMap];
    }

    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [OBAApplication.sharedApplication.userDefaults setInteger:tabBarController.selectedIndex forKey:kOBASelectedTabIndexDefaultsKey];
}

@end
