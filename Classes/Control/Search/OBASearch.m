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

#import "OBASearch.h"
#import "OBAStopV2.h"
#import "OBAPlacemark.h"
#import "OBAAgencyWithCoverage.h"
#import "OBANavigationTargetAnnotation.h"
#import "OBAProgressIndicatorImpl.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBAJsonDataSource.h"


static const float kSearchRadius = 400;


NSString * kOBASearchTypeParameter = @"OBASearchTypeParameter";
NSString * kOBASearchControllerSearchArgumentParameter = @"OBASearchControllerSearchArgumentParameter";
NSString * kOBASearchControllerSearchLocationParameter = @"OBASearchControllerSearchLocationParameter";


@interface OBASearch (Internal)

+ (OBANavigationTarget*) getNavigationTargetForSearchType:(OBASearchType)searchType;
+ (OBANavigationTarget*) getNavigationTargetForSearchType:(OBASearchType)searchType argument:(id)argument;

@end


@implementation OBASearch

+ (OBANavigationTarget*) getNavigationTargetForSearchNone {
	return [OBASearch getNavigationTargetForSearchType:OBASearchTypeNone];
}

+ (OBANavigationTarget*) getNavigationTargetForSearchLocationRegion:(MKCoordinateRegion)region {
	NSData * data = [NSData dataWithBytes:&region length:sizeof(MKCoordinateRegion)];	
	return [OBASearch getNavigationTargetForSearchType:OBASearchTypeRegion argument:data];
}

+ (OBANavigationTarget*) getNavigationTargetForSearchRoute:(NSString*)routeQuery {
	return [OBASearch getNavigationTargetForSearchType:OBASearchTypeRoute argument:routeQuery];
}

+ (OBANavigationTarget*) getNavigationTargetForSearchRouteStops:(NSString*)routeId {
	return [self getNavigationTargetForSearchType:OBASearchTypeRouteStops argument:routeId];
}

+ (OBANavigationTarget*) getNavigationTargetForSearchAddress:(NSString*)addressQuery {
	return [self getNavigationTargetForSearchType:OBASearchTypeAddress argument:addressQuery];	
}

+ (OBANavigationTarget*) getNavigationTargetForSearchPlacemark:(OBAPlacemark*)placemark {
	return [self getNavigationTargetForSearchType:OBASearchTypePlacemark argument:placemark];
}

+ (OBANavigationTarget*) getNavigationTargetForSearchStopCode:(NSString*)stopIdQuery {
	return [self getNavigationTargetForSearchType:OBASearchTypeStopId argument:stopIdQuery];	
}

+ (OBANavigationTarget*) getNavigationTargetForSearchAgenciesWithCoverage {
	return [self getNavigationTargetForSearchType:OBASearchTypeAgenciesWithCoverage];
}

+ (OBASearchType) getSearchTypeForNagivationTarget:(OBANavigationTarget*)target {

	// Update our target parameters
	NSDictionary * parameters = target.parameters;	
	NSNumber * searchTypeAsNumber = [parameters objectForKey:kOBASearchTypeParameter];
	
	if( ! searchTypeAsNumber )
		searchTypeAsNumber = [NSNumber numberWithInt:OBASearchTypeNone];
	
	switch ([searchTypeAsNumber intValue]) {
		case OBASearchTypeRegion:
			return OBASearchTypeRegion;
		case OBASearchTypeRoute:
			return OBASearchTypeRoute;
		case OBASearchTypeRouteStops:
			return OBASearchTypeRouteStops;
		case OBASearchTypeAddress:
			return OBASearchTypeAddress;
		case OBASearchTypePlacemark:
			return OBASearchTypePlacemark;
		case OBASearchTypeStopId:
			return OBASearchTypeStopId;
		case OBASearchTypeAgenciesWithCoverage:
			return OBASearchTypeAgenciesWithCoverage;
		default:
			return OBASearchTypeNone;
	}	
}

+ (id) getSearchTypeParameterForNagivationTarget:(OBANavigationTarget*)target {
	NSDictionary * params = target.parameters;
	return [params objectForKey:kOBASearchControllerSearchArgumentParameter];
}

@end



@implementation OBASearch (Internal)

+ (OBANavigationTarget*) getNavigationTargetForSearchType:(OBASearchType)searchType {
	return [self getNavigationTargetForSearchType:searchType argument:nil];
}

+ (OBANavigationTarget*) getNavigationTargetForSearchType:(OBASearchType)searchType argument:(id)argument {
	NSMutableDictionary * params = [NSMutableDictionary dictionary];
	[params setObject:[NSNumber numberWithInt:searchType] forKey:kOBASearchTypeParameter];

	if( argument )
		[params setObject:argument forKey:kOBASearchControllerSearchArgumentParameter];
    
	return [[[OBANavigationTarget alloc] initWithTarget:OBANavigationTargetTypeSearchResults parameters:params] autorelease];
}

@end
