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

//#import <UIKit/UIKit.h>
#import "OBAViewContext.h"
#import "OBANavigationTargetAware.h"
#import "OBAStop.h"
#import "OBALocationManager.h"
#import "OBASearchController.h"
#import "OBALocationManager.h"
#import "OBAGenericAnnotation.h"

@class OBASearchControllerImpl;
@class OBAProgressIndicatorView;

@interface OBASearchResultsMapViewController : UIViewController <OBANavigationTargetAware,OBASearchControllerDelegate, MKMapViewDelegate,UIActionSheetDelegate,UIAlertViewDelegate,OBALocationManagerDelegate> {
	
	OBAApplicationContext * _appContext;
	OBAViewContext * _context;
	
	OBASearchControllerImpl * _searchController;
	
	MKMapView * _mapView;
	NSMutableDictionary * _busStopIcons;
	
	UISegmentedControl * _searchTypeControl;
	UIBarButtonItem * _listButton;
	
	OBAGenericAnnotation * _locationAnnotation;
	UIImage * _busImage;
	
	BOOL _firstView;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)context;

@end
