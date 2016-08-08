//
//  OBADrawerUI.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBADrawerUI.h"
#import <Pulley/Pulley-Swift.h>
#import "OBADrawerViewController.h"
#import "OBASearchResultsMapViewController.h"
#import "OBASearchResultsListViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBABookmarksViewController.h"
#import <OBAKit/OBASearchResult.h>

@interface OBADrawerUI ()
@property(nonatomic,strong) PulleyViewController *pulleyController;
@property(nonatomic,strong) OBADrawerViewController *drawerController;
@property(nonatomic,strong) OBASearchResultsMapViewController *mapController;
@property(nonatomic,strong) OBASearchResultsListViewController *nearbyController;
@property(nonatomic,strong) OBARecentStopsViewController *recentsController;
@property(nonatomic,strong) OBABookmarksViewController *bookmarksController;
@end

@implementation OBADrawerUI

- (instancetype)init {
    self = [super init];

    if (self) {
        _mapController = [[OBASearchResultsMapViewController alloc] init];

        _drawerController = [[OBADrawerViewController alloc] init];

        _nearbyController = [[OBASearchResultsListViewController alloc] init];
        _nearbyController.rootViewStyle = OBARootViewStyleBlur;
        [self.class configureScrollViewInsets:_nearbyController.tableView];

        _recentsController = [[OBARecentStopsViewController alloc] init];
        _recentsController.rootViewStyle = OBARootViewStyleBlur;
        [self.class configureScrollViewInsets:_recentsController.tableView];

        _bookmarksController = [[OBABookmarksViewController alloc] init];
        _bookmarksController.rootViewStyle = OBARootViewStyleBlur;
        [self.class configureScrollViewInsets:_bookmarksController.tableView];

        _drawerController.viewControllers = @[_nearbyController, _recentsController, _bookmarksController];
        UINavigationController *drawerNavigation = [[UINavigationController alloc] initWithRootViewController:_drawerController];
        _pulleyController = [[PulleyViewController alloc] initWithContentViewController:_mapController drawerViewController:drawerNavigation];
    }
    return self;
}

/*
 I'm doing this because there's an annoying underlap issue with the navigation bar on the view controllers
 that are added to the drawer. Perhaps there's a clever, 'more right' way to do this that involves layout
 guides or something, but until I figure out what that might be, this'll do an ok job.
 
 44 is the height of a navigation bar, fyi.
 */
+ (void)configureScrollViewInsets:(UIScrollView*)scrollView {
    scrollView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0);
    scrollView.scrollIndicatorInsets = scrollView.contentInset;
}

#pragma mark - Protocol Methods

- (UIViewController*)rootViewController {
    return self.pulleyController;
}

- (void)performActionForShortcutItem:(nonnull UIApplicationShortcutItem *)shortcutItem completionHandler:(nonnull void (^)(BOOL))completionHandler {
    // TODO
}

- (void)applicationDidBecomeActive {
    // TODO
}

- (void)navigateToTargetInternal:(OBANavigationTarget*)navigationTarget {
    // TODO
}

- (void)updateSelectedTabIndex {
    // TODO
}


@end
