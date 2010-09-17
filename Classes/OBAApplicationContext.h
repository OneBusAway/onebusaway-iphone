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
#import "OBADataSourceConfig.h"
#import "OBALocationManager.h"
#import "OBAActivityListeners.h"
#import "OBAActivityLogger.h"

#import "OBANavigationTarget.h"


@class OBASearchResultsMapViewController;

@interface OBAApplicationContext : NSObject <UIApplicationDelegate> {
	
    NSManagedObjectContext * _managedObjectContext;  
	
	OBAModelDAO * _modelDao;
	OBAModelFactory * _modelFactory;

	OBALocationManager * _locationManager;
	OBAActivityListeners * _activityListeners;
	OBAActivityLogger * _activityLogger;
	
	OBADataSourceConfig * _obaDataSourceConfig;
	OBADataSourceConfig * _googleMapsDataSourceConfig;
	
	UIWindow * _window;
	UITabBarController * _tabBarController;
	OBASearchResultsMapViewController * _searchResultsMapViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController * tabBarController;

@property (nonatomic,readonly) OBAModelDAO * modelDao;
@property (nonatomic,readonly) OBAModelFactory * modelFactory;
@property (nonatomic,readonly) OBALocationManager * locationManager;
@property (nonatomic,readonly) OBAActivityListeners * activityListeners;

@property (nonatomic,readonly) OBADataSourceConfig * obaDataSourceConfig;
@property (nonatomic,readonly) OBADataSourceConfig * googleMapsDataSourceConfig;

- (void) navigateToTarget:(OBANavigationTarget*)navigationTarget;

@end
