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

#import <OBAKit/OBASearch.h>
#import <OBAKit/OBANavigationTargetAnnotation.h>
#import <OBAKit/OBASphericalGeometryLibrary.h>
#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBAPlacemark.h>
#import <OBAKit/OBAJsonDataSource.h>

NSString * const kOBASearchTypeParameter = @"OBASearchTypeParameter";
NSString * const kOBASearchControllerSearchArgumentParameter = @"OBASearchControllerSearchArgumentParameter";
NSString * const kOBASearchControllerSearchLocationParameter = @"OBASearchControllerSearchLocationParameter";

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
    return [self getNavigationTargetForSearchType:OBASearchTypeStops argument:routeId];
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

+ (OBASearchType) getSearchTypeForNavigationTarget:(OBANavigationTarget*)target {

    // Update our target parameters
    NSDictionary * parameters = target.parameters;    
    NSNumber * searchTypeAsNumber = parameters[kOBASearchTypeParameter];
    
    if( ! searchTypeAsNumber )
        searchTypeAsNumber = @(OBASearchTypeNone);
    
    switch ([searchTypeAsNumber intValue]) {
        case OBASearchTypeRegion:
            return OBASearchTypeRegion;
        case OBASearchTypeRoute:
            return OBASearchTypeRoute;
        case OBASearchTypeStops:
            return OBASearchTypeStops;
        case OBASearchTypeAddress:
            return OBASearchTypeAddress;
        case OBASearchTypePlacemark:
            return OBASearchTypePlacemark;
        case OBASearchTypeStopId:
            return OBASearchTypeStopId;
        default:
            return OBASearchTypeNone;
    }    
}

+ (id)getSearchTypeParameterForNavigationTarget:(OBANavigationTarget*)target {
    NSDictionary * params = target.parameters;
    return params[kOBASearchControllerSearchArgumentParameter];
}

+ (OBANavigationTarget*) getNavigationTargetForSearchType:(OBASearchType)searchType {
    return [self getNavigationTargetForSearchType:searchType argument:nil];
}

+ (OBANavigationTarget*) getNavigationTargetForSearchType:(OBASearchType)searchType argument:(id)argument {
    NSMutableDictionary * params = [NSMutableDictionary dictionary];
    params[kOBASearchTypeParameter] = [NSNumber numberWithInt:searchType];

    if( argument )
        params[kOBASearchControllerSearchArgumentParameter] = argument;
    
    return [OBANavigationTarget navigationTarget:OBANavigationTargetTypeSearchResults parameters:params];
}

@end
