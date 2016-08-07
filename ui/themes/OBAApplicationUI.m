//
//  OBAApplicationUI.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAApplicationUI.h"
#import "OBASearchResultsMapViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBABookmarksViewController.h"
#import "OBAInfoViewController.h"
#import "OBAStopViewController.h"
#import "OBAAnalytics.h"

static NSString *kOBASelectedTabIndexDefaultsKey = @"OBASelectedTabIndexDefaultsKey";
NSString * const kApplicationShortcutMap = @"org.onebusaway.iphone.shortcut.map";
NSString * const kApplicationShortcutRecents = @"org.onebusaway.iphone.shortcut.recents";
NSString * const kApplicationShortcutBookmarks = @"org.onebusaway.iphone.shortcut.bookmarks";

@interface OBAApplicationUI ()<UITabBarControllerDelegate>
@property(nonatomic, strong,readwrite) UITabBarController *tabBarController;

@property(nonatomic, strong) UINavigationController *mapNavigationController;
@property(strong) OBASearchResultsMapViewController *mapViewController;

@property(strong) UINavigationController *recentsNavigationController;
@property(strong) OBARecentStopsViewController *recentsViewController;

@property(strong) UINavigationController *bookmarksNavigationController;
@property(strong) UIViewController *bookmarksViewController;

@property(strong) UINavigationController *infoNavigationController;
@property(strong) OBAInfoViewController *infoViewController;
@end

@implementation OBAApplicationUI

- (instancetype)init {

    if (self) {
        _tabBarController = [[UITabBarController alloc] init];

        _mapViewController = [[OBASearchResultsMapViewController alloc] init];
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

- (void)performActionForShortcutItem:(nonnull UIApplicationShortcutItem *)shortcutItem completionHandler:(nonnull void (^)(BOOL))completionHandler {

    NSString *shortcutIdentifier = shortcutItem.type;

    if ([shortcutIdentifier isEqualToString:kApplicationShortcutMap]) {
        [self.tabBarController setSelectedViewController:self.mapNavigationController];

        [self.mapNavigationController popToRootViewControllerAnimated:NO];
        [self.mapViewController updateLocation:self];
    }
    else if ([shortcutIdentifier isEqualToString:kApplicationShortcutBookmarks]) {
        [self.tabBarController setSelectedViewController:self.bookmarksNavigationController];

        [self.bookmarksNavigationController popToRootViewControllerAnimated:NO];
    }
    else if ([shortcutIdentifier isEqualToString:kApplicationShortcutRecents]) {
        [self.tabBarController setSelectedViewController:self.recentsNavigationController];

        NSArray *stopIds = (NSArray *)shortcutItem.userInfo[@"stopIds"];
        if (stopIds.count > 0) {
            OBAStopViewController *vc = [[OBAStopViewController alloc] initWithStopID:stopIds[0]];
            [self.recentsNavigationController popToRootViewControllerAnimated:NO];
            [self.recentsNavigationController pushViewController:vc animated:YES];
        }
    }

    // update kOBASelectedTabIndexDefaultsKey, since the delegate doesn't fire
    // otherwise applicationDidBecomeActive: will switch us away
    [self tabBarController:self.tabBarController didSelectViewController:self.tabBarController.selectedViewController];
    
    completionHandler(YES);
}

- (void)applicationDidBecomeActive {
    self.tabBarController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kOBASelectedTabIndexDefaultsKey];
}

- (void)updateSelectedTabIndex {
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

- (void)navigateToTargetInternal:(OBANavigationTarget*)navigationTarget {
    [self.mapNavigationController popToRootViewControllerAnimated:NO];

    if (OBANavigationTargetTypeSearchResults == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.mapNavigationController];
        self.mapViewController.navigationTarget = navigationTarget;
    }
    else if (OBANavigationTargetTypeContactUs == navigationTarget.target) {
        [self.tabBarController setSelectedViewController:self.infoNavigationController];
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

@end
