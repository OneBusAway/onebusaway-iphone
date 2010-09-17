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

#import "OBAViewContext.h"
#import "OBACommon.h"

#import "OBABookmarksViewController.h"


// All the ViewControllers
#import "OBASearchViewController.h"
#import "OBASearchResultsMapViewController.h"

#import "OBARecentStopsViewController.h"
#import "OBAStopViewController.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBASettingsViewController.h"

#import "OBAActivityLoggingViewController.h"
#import "OBAActivityAnnotationViewController.h"
#import "OBAUploadViewController.h"
#import "OBALockViewController.h"

#import "OBASearchController.h"
#import "OBASearchControllerImpl.h"
#import "OBAStopAndPredictedArrivalsSearch.h"



@interface OBAViewContext (Private)

/*
- (UIViewController*) getViewControllerForTarget:(OBANavigationTarget*)target context:(OBAViewContext*)context;
- (id<OBASearchController>) getSearchControllerForContext:(OBAViewContext*)context;
- (OBAStopAndPredictedArrivalsSearch*) getStopAndPredictdArrivalSearch:(NSDictionary*)parameters;
*/

@end


@implementation OBAViewContext

@synthesize appContext = _appContext;
@synthesize target = _target;

- (id) initWithAppContext:(OBAApplicationContext*)appContext navigationTarget:(OBANavigationTarget*)target {
	if( self = [super init] ) {
		_appContext = [appContext retain];
		_target = [target retain];
	}
	return self;
}

- (void) dealloc {
	[_appContext release];
	[_target release];
	[super dealloc];
}

#pragma mark UIViewController Methods

/*
- (UIViewController*) getViewControllerForTargetType:(OBANavigationTargetType)targetType {
	OBANavigationTarget * target = [[[OBANavigationTarget alloc] initWithTarget:targetType] autorelease];
	return [self getViewControllerForTarget:target];
}

- (UIViewController*) getViewControllerForTargetType:(OBANavigationTargetType)targetType parameters:(NSDictionary*)parameters {
	OBANavigationTarget * target = [self getNavigationTargetForTargetType:targetType parameters:parameters];
	return [self getViewControllerForTarget:target];
}

- (UIViewController*) getViewControllerForTarget:(OBANavigationTarget*)target {
	OBAViewContext * context = [self getContextForTarget:target];
	return [self getViewControllerForTarget:target context:context];
}
*/
/*
- (OBANavigationTarget*) getNavigationTargetForTargetType:(OBANavigationTargetType)targetType parameters:(NSDictionary*)parameters {
	return [[[OBANavigationTarget alloc] initWithTarget:targetType parameters:parameters] autorelease];
}

- (OBAViewContext*) getContextForTarget:(OBANavigationTarget*)target {
	return [[[OBAViewContext alloc] initWithAppContext:_appContext navigationTarget:target] autorelease];
}

- (void) navigateToTarget:(OBANavigationTarget*)target {
	[_appContext navigateToTarget:target];
}
*/
@end

@implementation OBAViewContext (Private)

/*
- (UIViewController*) getViewControllerForTarget:(OBANavigationTarget*)target context:(OBAViewContext*)context {

	switch(target.target) {
		case OBANavigationTargetTypeRoot:
			break;
		case OBANavigationTargetTypeSearch: {
			return [[[OBASearchViewController alloc] initWithContext:context] autorelease];
		}
		case OBANavigationTargetTypeSearchResults: {
			
			NSLog(@"NO LONGER SUPPORTED");
			return nil;
		}
		case OBANavigationTargetTypeBookmarks: {
			return [[[OBABookmarksViewController alloc] initWithContext:context] autorelease];
		}
		case OBANavigationTargetTypeRecentStops:
			return [[[OBARecentStopsViewController alloc] initWithContext:context] autorelease]; 
		case OBANavigationTargetTypeStop: {
			OBAStopAndPredictedArrivalsSearch * search = [self getStopAndPredictdArrivalSearch:target.parameters];
			return [[[OBAStopViewController alloc] initWithContext:context searchController:search] autorelease];
		}
		case OBANavigationTargetTypeEditBookmark:
			return [[[OBAEditStopBookmarkViewController alloc] initWithContext:context] autorelease];
		case OBANavigationTargetTypeSettings:
			return [[[OBASettingsViewController alloc] initWithContext:context] autorelease];
		case OBANavigationTargetTypeActivityLogging:
			return [[[OBAActivityLoggingViewController alloc] initWithContext:context] autorelease];
		case OBANavigationTargetTypeActivityAnnotation:
			return [[[OBAActivityAnnotationViewController alloc] initWithContext:context] autorelease];
		case OBANavigationTargetTypeActivityUpload:
			return [[[OBAUploadViewController alloc] initWithContext:context] autorelease];
		case OBANavigationTargetTypeActivityLock:
			return [[[OBALockViewController alloc] initWithContext:context] autorelease];
	}
	
	return nil;
}
*/

@end
