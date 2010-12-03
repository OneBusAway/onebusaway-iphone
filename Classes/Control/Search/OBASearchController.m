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

#import "OBASearchController.h"
#import "OBAPlacemark.h"
#import "OBAProgressIndicatorImpl.h"
#import "OBALogger.h"


@interface OBASearchController (Internal)

- (id<OBAModelServiceRequest>) requestForTarget:(OBANavigationTarget*)target;
- (NSString*) progressCompleteMessageForSearchType;

-(void) fireUpdateFromList:(OBAListWithRangeAndReferencesV2*)list;
-(void) fireUpdate:(OBASearchResult*)result;
-(void) fireError:(NSError*)error;

@end


#pragma mark OBASearchController

@implementation OBASearchController

@synthesize delegate = _delegate;
@synthesize searchType = _searchType;
@synthesize result = _result;
@synthesize progress = _progress;
@synthesize error = _error;

- (id) initWithAppContext:(OBAApplicationContext*)context {
	
	if ( self = [super init] ) {
		_modelService = [context.modelService retain];
		_searchType = OBASearchTypeNone;
		_progress = [[OBAProgressIndicatorImpl alloc] init];
	}
	return self;
}

-(void) dealloc {
	
	[self cancelOpenConnections];

	[_modelService release];
	
	[_progress release];
	
	[_target release];
	[_result release];
	
	[_lastCurrentLocationSearch release];
	
	[super dealloc];
}

-(void) searchWithTarget:(OBANavigationTarget*)target {
	
	[self cancelOpenConnections];
	
	_target = [NSObject releaseOld:_target retainNew:target];	
	_searchType = [OBASearch getSearchTypeForNagivationTarget:target];	
	
	// Short circuit if the request is NONE
	if( _searchType == OBASearchTypeNone ) {
		OBASearchResult * result = [OBASearchResult result];
		result.searchType = OBASearchTypeNone;
		[self fireUpdate:result];
		[_progress setMessage:@"" inProgress:FALSE progress:0];
		return;
	}
	
	_request = [[self requestForTarget:target] retain];
	[_progress setMessage:@"Connecting..." inProgress:TRUE progress:0];
	
}

-(void) searchPending {
	[self cancelOpenConnections];
	[_target release];
	_target = nil;
	_searchType = OBASearchTypePending;
}

-(OBANavigationTarget*) getSearchTarget {
	return _target;
}

- (id) searchParameter {
	return [OBASearch getSearchTypeParameterForNagivationTarget:_target];
}

-(CLLocation*) searchLocation {
	return [_target parameterForKey:kOBASearchControllerSearchLocationParameter];
}

- (void) setSearchLocation:(CLLocation*)location { 
	if( location ) 
		[_target setParameter:location forKey:kOBASearchControllerSearchLocationParameter];
}

- (void) cancelOpenConnections {
	[_request cancel];
	[_request release];
	_request = nil;
	
	_searchType = OBASearchTypeNone;
	_result = [NSObject releaseOld:_result retainNew:nil];
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
	
	NSString * message = [self progressCompleteMessageForSearchType];
	[_progress setMessage:message inProgress:FALSE progress:0];

	switch (_searchType ) {

		case OBASearchTypeRegion:
			[self fireUpdateFromList:obj];
			break;
		
		case OBASearchTypeRoute: {
			OBAListWithRangeAndReferencesV2 * list = obj;
			if( [list count] == 1 ) {
				OBARouteV2 * route = [list.values objectAtIndex:0];
				OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchRouteStops:route.routeId];
				[self performSelector:@selector(searchWithTarget:) withObject:target afterDelay:0];
				//[self searchWithTarget: target];
			}
			else {
				[self fireUpdateFromList:list];
			}
			break;
		}

		case OBASearchTypeRouteStops: {
			OBAStopsForRouteV2 * stopsForRoute = obj;
			OBASearchResult * result = [OBASearchResult result];
			result.values = [stopsForRoute stops];
			result.additionalValues = stopsForRoute.polylines;
			[self fireUpdate:result];
			break;
		}
			
		case OBASearchTypeAddress: {
			NSArray * placemarks = obj;
			if( [placemarks count] == 1 ) {
				OBAPlacemark * placemark = [placemarks objectAtIndex:0];
				OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchPlacemark:placemark];
				[self performSelector:@selector(searchWithTarget:) withObject:target afterDelay:0];
			}
			else {
				OBASearchResult * result = [OBASearchResult result];
				result.values = placemarks;
				[self fireUpdate:result];
			}
			break;
		}

		case OBASearchTypePlacemark: {
			OBASearchResult * result = [OBASearchResult resultFromList:obj];
			OBAPlacemark * placemark = [_target parameterForKey:kOBASearchControllerSearchArgumentParameter];
			result.additionalValues = [NSArray arrayWithObject:placemark];
			[self fireUpdate:result];
			break;
		}

		case OBASearchTypeStopId:
			[self fireUpdateFromList:obj];
			break;

		case OBASearchTypeAgenciesWithCoverage:
			[self fireUpdateFromList:obj];
			break;
	}
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
	if( code == 404 )
		[_progress setMessage:@"Not found" inProgress:FALSE progress:0];
	else
		[_progress setMessage:@"Server error" inProgress:FALSE progress:0];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
	[_progress setMessage:@"Error connecting" inProgress:FALSE progress:0];
	[self fireError:error];
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
	[_progress setInProgress:TRUE progress:progress];
}

@end


@implementation OBASearchController (Internal)
   
- (id<OBAModelServiceRequest>) requestForTarget:(OBANavigationTarget*)target {
	
	// Update our target parameters
	OBASearchType type = [OBASearch getSearchTypeForNagivationTarget:target];
	
	switch (type) {
			
		case OBASearchTypeRegion: {
			NSData * data = [OBASearch getSearchTypeParameterForNagivationTarget:target];
			MKCoordinateRegion region;
			[data getBytes:&region];
			return [_modelService requestStopsForRegion:region withDelegate:self withContext:nil];
		}
		case OBASearchTypeRoute: {
			NSString * routeQuery = [OBASearch getSearchTypeParameterForNagivationTarget:target];
			return [_modelService requestRoutesForQuery:routeQuery withDelegate:self withContext:nil];
		}
		case OBASearchTypeRouteStops: {
			NSString * routeId = [OBASearch getSearchTypeParameterForNagivationTarget:target];
			return [_modelService requestStopsForRoute:routeId withDelegate:self withContext:nil];
		}
		case OBASearchTypeAddress: {
			NSString * addressQuery = [OBASearch getSearchTypeParameterForNagivationTarget:target];
			return [_modelService placemarksForAddress:addressQuery withDelegate:self withContext:nil];
		}
		case OBASearchTypePlacemark: {
			OBAPlacemark * placemark = [OBASearch getSearchTypeParameterForNagivationTarget:target];
			return [_modelService requestStopsForPlacemark:placemark withDelegate:self withContext:nil];
		}			
		case OBASearchTypeStopId: {
			NSString * stopCode = [OBASearch getSearchTypeParameterForNagivationTarget:target];
			return [_modelService requestStopsForQuery:stopCode withDelegate:self withContext:nil];
		}
		case OBASearchTypeAgenciesWithCoverage:
			return [_modelService requestAgenciesWithCoverageWithDelegate:self withContext:nil];
			
		default:
			break;
	}
	
	return nil;
}

-(NSString*) progressCompleteMessageForSearchType {

	NSString * title = nil;
	
	switch (_searchType) {
		case OBASearchTypeNone:
			title = @"";
			break;
		case OBASearchTypeRegion:
		case OBASearchTypePlacemark:
		case OBASearchTypeStopId:			
		case OBASearchTypeRouteStops:
			title = @"Stops";
			break;
		case OBASearchTypeRoute:		
			title = @"Routes";
			break;
		case OBASearchTypeAddress:
			title = @"Places";
			break;
		case OBASearchTypeAgenciesWithCoverage:
			title = @"Agencies";
			break;
		default:			
			break;
	}
	
	return title;
}

-(void) fireUpdateFromList:(OBAListWithRangeAndReferencesV2*)list {
	OBASearchResult * result = [OBASearchResult resultFromList:list];
	[self fireUpdate:result];		  
}

-(void) fireUpdate:(OBASearchResult*)result {
	result.searchType = _searchType;
	_result = [NSObject releaseOld:_result retainNew:result];
	if( _delegate )
		[_delegate handleSearchControllerUpdate:_result];
}

- (void) fireError:(NSError*)error {
	self.error = error;
	if( _delegate && [_delegate respondsToSelector:@selector(handleSearchControllerError:)] ) {
		[_delegate handleSearchControllerError:error];
	}	
}

@end
