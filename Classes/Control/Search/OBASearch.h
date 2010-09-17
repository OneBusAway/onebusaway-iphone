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

#import "OBAProgressIndicatorSource.h"
#import "OBAPlacemark.h"
#import "OBANavigationTarget.h"
#import "OBAListWithRangeAndReferencesV2.h"


extern NSString * kOBASearchTypeParameter;
extern NSString * kOBASearchControllerSearchArgumentParameter;
extern NSString * kOBASearchControllerSearchLocationParameter;

typedef enum {
	OBASearchTypeNone=0,
	OBASearchTypePending,
	OBASearchTypeRegion,
	OBASearchTypeRoute,
	OBASearchTypeRouteStops,
	OBASearchTypeAddress,
	OBASearchTypePlacemark,
	OBASearchTypeStopId,
	OBASearchTypeAgenciesWithCoverage
} OBASearchType;


@interface OBASearch : NSObject

+ (OBANavigationTarget*) getNavigationTargetForSearchNone;
+ (OBANavigationTarget*) getNavigationTargetForSearchLocationRegion:(MKCoordinateRegion)region;
+ (OBANavigationTarget*) getNavigationTargetForSearchRoute:(NSString*)routeQuery;
+ (OBANavigationTarget*) getNavigationTargetForSearchRouteStops:(NSString*)routeId;
+ (OBANavigationTarget*) getNavigationTargetForSearchAddress:(NSString*)addressQuery;
+ (OBANavigationTarget*) getNavigationTargetForSearchPlacemark:(OBAPlacemark*)placemark;
+ (OBANavigationTarget*) getNavigationTargetForSearchStopCode:(NSString*)stopIdQuery;
+ (OBANavigationTarget*) getNavigationTargetForSearchAgenciesWithCoverage;

+ (OBASearchType) getSearchTypeForNagivationTarget:(OBANavigationTarget*)target;
+ (id) getSearchTypeParameterForNagivationTarget:(OBANavigationTarget*)target;

@end
	

