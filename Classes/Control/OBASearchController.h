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


extern NSString * kOBASearchControllerSearchTypeParameter;
extern NSString * kOBASearchControllerSearchArgumentParameter;
extern NSString * kOBASearchControllerSearchLocationParameter;

typedef enum {
	OBASearchControllerSearchTypeNone=0,
	OBASearchControllerSearchTypeCurrentLocation,
	OBASearchControllerSearchTypeRegion,
	OBASearchControllerSearchTypeRoute,
	OBASearchControllerSearchTypeRouteStops,
	OBASearchControllerSearchTypeAddress,
	OBASearchControllerSearchTypePlacemark,
	OBASearchControllerSearchTypeStopId,
	OBASearchControllerSearchTypeAgenciesWithCoverage
} OBASearchControllerSearchType;


# pragma mark OBASearchControllerResult Interface

@interface OBASearchControllerResult : NSObject
{
	OBASearchControllerSearchType _searchType;
	NSArray * _stops;
	NSArray * _placemarks;
	NSArray * _agenciesWithCoverage;
	NSArray * _routes;
	BOOL _stopLimitExceeded;
}

@property (nonatomic) OBASearchControllerSearchType searchType;
@property (nonatomic,retain) NSArray * stops;
@property (nonatomic,retain) NSArray * placemarks;
@property (nonatomic,retain) NSArray * agenciesWithCoverage;
@property (nonatomic,retain) NSArray * routes;
@property (nonatomic) BOOL stopLimitExceeded;

+ (OBASearchControllerResult*) result;

@end


#pragma mark OBASearchControllerDelegate Protocol

@protocol OBASearchControllerDelegate <NSObject>

- (void) handleSearchControllerUpdate:(OBASearchControllerResult*)result;

@optional

- (void) handleSearchControllerError:(NSError*)error;

@end


#pragma mark OBASearchController Protocol

@protocol OBASearchController <NSObject>
	
@property (nonatomic,assign) id<OBASearchControllerDelegate> delegate;
@property (nonatomic,readonly) OBASearchControllerSearchType searchType;
@property (nonatomic,readonly) OBASearchControllerResult * result;

@property (nonatomic,readonly) CLLocation * searchLocation;
		   
@property (nonatomic,retain) NSObject<OBAProgressIndicatorSource>* progress;
@property (nonatomic,retain) NSError * error;

-(void) searchWithTarget:(OBANavigationTarget*)target;
-(OBANavigationTarget*) getSearchTarget;
-(void) cancelOpenConnections;

@end

@interface OBASearchControllerFactory : NSObject

+ (OBANavigationTarget*) getNavigationTargetForSearchCurrentLocation;
+ (OBANavigationTarget*) getNavigationTargetForSearchLocationRegion:(MKCoordinateRegion)region;
+ (OBANavigationTarget*) getNavigationTargetForSearchRoute:(NSString*)routeQuery;
+ (OBANavigationTarget*) getNavigationTargetForSearchRouteStops:(NSString*)routeId;
+ (OBANavigationTarget*) getNavigationTargetForSearchAddress:(NSString*)addressQuery;
+ (OBANavigationTarget*) getNavigationTargetForSearchPlacemark:(OBAPlacemark*)placemark;
+ (OBANavigationTarget*) getNavigationTargetForSearchStopCode:(NSString*)stopIdQuery;
+ (OBANavigationTarget*) getNavigationTargetForSearchAgenciesWithCoverage;

@end
	

