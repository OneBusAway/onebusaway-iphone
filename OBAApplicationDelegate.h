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

#import "OBAModelDAO.h"
#import "OBAModelFactory.h"
#import "OBAModelService.h"
#import "OBADataSourceConfig.h"
#import "OBALocationManager.h"
#import "OBANavigationTarget.h"
#import "OBAReferencesV2.h"
#import "GAI.h"

@class OBASearchResultsMapViewController;
@class OBARecentStopsViewController;
@class OBABookmarksViewController;
@class OBAInfoViewController;
@class OBAStopIconFactory;
@class OBARegionListViewController;

@interface OBAApplicationDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate> {
    
    OBAReferencesV2 * _references;
    OBAModelDAO * _modelDao;
    OBAModelService * _modelService;
    
    OBALocationManager * _locationManager;

    OBAStopIconFactory * _stopIconFactory;
    
    UINavigationController *_regionNavigationController;
    OBARegionListViewController *_regionListViewController;
}

@property(nonatomic, strong) UIWindow *window;
@property(nonatomic, strong) UITabBarController *tabBarController;

@property(nonatomic, strong) UINavigationController *mapNavigationController;
@property(strong) OBASearchResultsMapViewController *mapViewController;

@property(strong) UINavigationController *recentsNavigationController;
@property(strong) OBARecentStopsViewController *recentsViewController;

@property(strong) UINavigationController *bookmarksNavigationController;
@property(strong) OBABookmarksViewController *bookmarksViewController;

@property(strong) UINavigationController *infoNavigationController;
@property(strong) OBAInfoViewController *infoViewController;


@property(nonatomic,readonly) OBAReferencesV2 * references;
@property(nonatomic,readonly) OBAModelDAO * modelDao;
@property(nonatomic,readonly) OBAModelService * modelService;

@property(nonatomic,readonly) OBAStopIconFactory * stopIconFactory;

@property(nonatomic,readonly) OBALocationManager * locationManager;

@property(nonatomic,readonly) BOOL active;

@property(nonatomic, strong) id<GAITracker> tracker;

- (void) navigateToTarget:(OBANavigationTarget*)navigationTarget;
- (void) refreshSettings;
- (void) regionSelected;
- (void) showRegionListViewController;

@end
