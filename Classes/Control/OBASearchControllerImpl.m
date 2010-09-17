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

#import "OBASearchControllerImpl.h"
#import "OBARoute.h"
#import "OBAPlacemark.h"
#import "OBAAgencyWithCoverage.h"
#import "OBANavigationTargetAnnotation.h"
#import "OBAProgressIndicatorImpl.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBAJsonDataSource.h"
#import "OBALogger.h"


static const float kSearchRadius = 400;

@interface OBASearchControllerImpl (Internal)

- (OBASearchControllerSearchType) searchTypeForNumber:(NSNumber*)number;

- (CLLocation*) currentOrDefaultLocationToSearch;

-(void) searchNone;
-(void) searchByLocationRegion:(MKCoordinateRegion)region;
-(void) searchByRoute:(NSString*)routeQuery;
-(void) searchByRouteStops:(NSString*)routeId;
-(void) searchByStopId:(NSString*)stopIdQuery;
-(void) searchByAddress:(NSString*)addressQuery;
-(void) searchByPlacemark:(OBAPlacemark*)placemark;
-(void) searchForAgenciesWithCoverage;

- (void) requestPath:(NSString*)path withArgs:(NSString*)args searchType:(OBASearchControllerSearchType)searchType;
- (void) requestPath:(NSString*)path withArgs:(NSString*)args searchType:(OBASearchControllerSearchType)searchType jsonDataSource:(OBAJsonDataSource*)jsonDataSource;

-(NSString*) progressCompleteMessageForSearchType;

-(void) handleSearchByLocationRegion:(id)jsonObject;
-(void) handleSearchByRoute:(id)jsonObject;
-(void) handleSearchByRouteStops:(id)jsonObject;
-(void) handleSearchByStopId:(id)jsonObject;
-(void) handleSearchByAddress:(id)jsonObject;
-(void) handleSearchByPlacemark:(id)jsonObject;
-(void) handleSearchForAgenciesWithCoverage:(id)jsonObject;

-(NSArray*) parseStops:(NSArray*)stopArray;

-(void) fireStopsFromJsonObject:(id)jsonObject;
-(void) fireStops:(NSArray*)stops limitExceeded:(BOOL)limitExceeded;
-(void) firePlacemarks:(NSArray*)placemarks;
-(void) fireStops:(NSArray*)stops placemarks:(NSArray*)placemarks limitExceeded:(BOOL)limitExceeded;
-(void) fireAgenciesWithCoverage:(NSArray*)agenciesWithCoverage;

-(void) fireUpdate:(OBASearchControllerResult*)result;
-(void) fireError:(NSError*)error;

- (NSString*) escapeStringForUrl:(NSString*)url;

@end


#pragma mark OBASearchControllerImpl

@implementation OBASearchControllerImpl

@synthesize delegate = _delegate;
@synthesize searchType = _searchType;
@synthesize result = _result;
@synthesize progress = _progress;
@synthesize error = _error;

@synthesize searchFilterString = _searchFilterString;


- (id) initWithAppContext:(OBAApplicationContext*)context {
	
	if ( self = [super init] ) {
		_appContext = [context retain];
		_searchType = OBASearchControllerSearchTypeNone;
		_progress = [[OBAProgressIndicatorImpl alloc] init];
		_locationManager = [context.locationManager retain];
		
		_obaDataSource = [[OBAJsonDataSource alloc] initWithConfig:context.obaDataSourceConfig];
		_googleMapsDataSource = [[OBAJsonDataSource alloc] initWithConfig:context.googleMapsDataSourceConfig];
	}
	return self;
}

-(void) dealloc {
	
	[self cancelOpenConnections];

	[_appContext release];
	
	[_progress release];
	[_locationManager release];
	
	[_obaDataSource release];
	[_googleMapsDataSource release];
	
	[_target release];
	[_searchContext release];
	[_lastCurrentLocationSearch release];
	[_result release];
    [_searchFilterString release];
	
	[super dealloc];
}

-(void) searchWithTarget:(OBANavigationTarget*)target {
	
	_target = [NSObject releaseOld:_target retainNew:target];
	
	// Update our target parameters
	NSDictionary * parameters = target.parameters;	
	NSNumber * searchTypeAsNumber = [parameters objectForKey:kOBASearchControllerSearchTypeParameter];
	
	if( ! searchTypeAsNumber )
		searchTypeAsNumber = [NSNumber numberWithInt:OBASearchControllerSearchTypeNone];
	
	OBASearchControllerSearchType searchType = [self searchTypeForNumber:searchTypeAsNumber];
	
	@synchronized(self) {
		[self cancelOpenConnections];
		
		_searchType = searchType;
		_result = [NSObject releaseOld:_result retainNew:nil];
	}

	switch (_searchType) {
		case OBASearchControllerSearchTypeNone:
			[self searchNone];
			break;

		case OBASearchControllerSearchTypeRegion: {
			NSData * data = [parameters objectForKey:kOBASearchControllerSearchArgumentParameter];
			MKCoordinateRegion region;
			[data getBytes:&region];
			[self searchByLocationRegion:region];
			break;
		}
		case OBASearchControllerSearchTypeRoute: {
			NSString * routeQuery = [parameters objectForKey:kOBASearchControllerSearchArgumentParameter];
			[self searchByRoute:routeQuery];
			break;			
		}
		case OBASearchControllerSearchTypeRouteStops: {
			NSString * routeId = [parameters objectForKey:kOBASearchControllerSearchArgumentParameter];
			[self searchByRouteStops:routeId];
			break;						
		}
		case OBASearchControllerSearchTypeAddress: {
			NSString * addressQuery = [parameters objectForKey:kOBASearchControllerSearchArgumentParameter];
			[self searchByAddress:addressQuery];
			break;						
		}
		case OBASearchControllerSearchTypePlacemark: {
			OBAPlacemark * placemark = [parameters objectForKey:kOBASearchControllerSearchArgumentParameter];
			[self searchByPlacemark:placemark];
			break;						
		}			
		case OBASearchControllerSearchTypeStopId: {
			NSString * stopCode = [parameters objectForKey:kOBASearchControllerSearchArgumentParameter];
			[self searchByStopId:stopCode];
			break;						
		}
		case OBASearchControllerSearchTypeAgenciesWithCoverage:
			[self searchForAgenciesWithCoverage];
			break;
		default:
			break;
	}	
}

-(OBANavigationTarget*) getSearchTarget {
	return _target;
}

-(CLLocation*) searchLocation {
	return [_target parameterForKey:kOBASearchControllerSearchLocationParameter];
}

- (void) setSearchLocation:(CLLocation*)location { 
	if( location ) 
		[_target setParameter:location forKey:kOBASearchControllerSearchLocationParameter];
}

- (void) cancelOpenConnections {
	[_obaDataSource cancelOpenConnections];
	[_googleMapsDataSource cancelOpenConnections];
}

#pragma mark OBADataSourceDelegate Methods

- (void)connection:(id<OBADataSourceConnection>)connection withProgress:(float)progress {
	[_progress setInProgress:TRUE progress:progress];
}

- (void)connectionDidFinishLoading:(id<OBADataSourceConnection>)connection withObject:(id)obj context:(id)context {
	
	OBASearchControllerSearchType searchType = OBASearchControllerSearchTypeNone;
	
	@synchronized(self) {		
		if( ! [context isEqual:_searchContext] )
			return;
		searchType = _searchType;
	}
	
	//NSString * message = [NSString stringWithFormat:@"Updated: %@", [OBACommon getTimeAsString]];
	NSString * message = [self progressCompleteMessageForSearchType];
	[_progress setMessage:message inProgress:FALSE progress:0];
	
	switch (searchType ) {
		case OBASearchControllerSearchTypeRegion:
			[self handleSearchByLocationRegion:obj];
			break;
		case OBASearchControllerSearchTypeRoute:
			[self handleSearchByRoute:obj];
			break;
		case OBASearchControllerSearchTypeRouteStops:
			[self handleSearchByRouteStops:obj];
			break;				
		case OBASearchControllerSearchTypeAddress:
			[self handleSearchByAddress:obj];
			break;
		case OBASearchControllerSearchTypePlacemark:
			[self handleSearchByPlacemark:obj];
			break;
		case OBASearchControllerSearchTypeStopId:
			[self handleSearchByStopId:obj];
			break;
		case OBASearchControllerSearchTypeAgenciesWithCoverage:
			[self handleSearchForAgenciesWithCoverage:obj];
			break;
	}
}

- (void)connectionDidFail:(id<OBADataSourceConnection>)connection withError:(NSError *)localError context:(id)context {
	[_progress setMessage:@"Error connecting" inProgress:FALSE progress:0];
	[self fireError:localError];
}

@end

@implementation OBASearchControllerImpl (Internal)

- (OBASearchControllerSearchType) searchTypeForNumber:(NSNumber*)number {
	switch ([number intValue]) {
		case OBASearchControllerSearchTypeRegion:
			return OBASearchControllerSearchTypeRegion;
		case OBASearchControllerSearchTypeRoute:
			return OBASearchControllerSearchTypeRoute;
		case OBASearchControllerSearchTypeRouteStops:
			return OBASearchControllerSearchTypeRouteStops;
		case OBASearchControllerSearchTypeAddress:
			return OBASearchControllerSearchTypeAddress;
		case OBASearchControllerSearchTypePlacemark:
			return OBASearchControllerSearchTypePlacemark;
		case OBASearchControllerSearchTypeStopId:
			return OBASearchControllerSearchTypeStopId;
		case OBASearchControllerSearchTypeAgenciesWithCoverage:
			return OBASearchControllerSearchTypeAgenciesWithCoverage;
		default:
			return OBASearchControllerSearchTypeNone;
	}		
}

- (CLLocation*) currentOrDefaultLocationToSearch {
	
	CLLocation * location = _locationManager.currentLocation;
	
	if( ! location )  {
		OBAModelDAO * modelDao = _appContext.modelDao;
		location = modelDao.mostRecentLocation;
	}
	
	if( ! location )
		location = [[[CLLocation alloc] initWithLatitude:47.61229680032385  longitude:-122.3386001586914] autorelease];
	
	self.searchLocation = location;

	return location;
}

-(void) searchNone {
	OBASearchControllerResult * result = [OBASearchControllerResult result];
	[self fireUpdate:result];
}

-(void) searchByLocationRegion:(MKCoordinateRegion)region {
    // clear search filter description
    self.searchFilterString = nil;
    
    // request search
	CLLocationCoordinate2D coord = region.center;
	MKCoordinateSpan span = region.span;
	
	CLLocation * location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
	_lastCurrentLocationSearch = [NSObject releaseOld:_lastCurrentLocationSearch retainNew:location];
    [location release];
	
	NSString * args = [NSString stringWithFormat:@"lat=%f&lon=%f&latSpan=%f&lonSpan=%f", coord.latitude, coord.longitude, span.latitudeDelta, span.longitudeDelta];
	[self requestPath:@"/api/where/stops-for-location.json" withArgs:args searchType:OBASearchControllerSearchTypeRegion];
}

-(void) searchByRoute:(NSString*)routeQuery {
    // update search filter description
    self.searchFilterString = [NSString stringWithFormat:@"route %@", routeQuery];
	
    // equest search
    CLLocation * location = [self currentOrDefaultLocationToSearch];
	CLLocationCoordinate2D coord = location.coordinate;

	routeQuery = [self escapeStringForUrl:routeQuery];
	NSString * args = [NSString stringWithFormat:@"lat=%f&lon=%f&query=%@", coord.latitude, coord.longitude,routeQuery];
	
    [self requestPath:@"/api/where/routes-for-location.json" withArgs:args searchType:OBASearchControllerSearchTypeRoute];

}

-(void) searchByRouteStops:(NSString*)routeId {
	NSString * path = [NSString stringWithFormat:@"/api/where/stops-for-route/%@.json", routeId];
	[self requestPath: path withArgs:nil searchType:OBASearchControllerSearchTypeRouteStops];
}

-(void) searchByStopId:(NSString*)stopIdQuery {
    // update search filter description
    self.searchFilterString = [NSString stringWithFormat:@"stop id %@", stopIdQuery];

	// request search
    CLLocation * location = [self currentOrDefaultLocationToSearch];
	CLLocationCoordinate2D coord = location.coordinate;
	
    stopIdQuery = [self escapeStringForUrl:stopIdQuery];
	NSString * args = [NSString stringWithFormat:@"lat=%f&lon=%f&query=%@", coord.latitude, coord.longitude, stopIdQuery];

	[self requestPath:@"/api/where/stops-for-location.json" withArgs:args searchType:OBASearchControllerSearchTypeStopId];
}

-(void) searchByAddress:(NSString*)addressQuery {
    // update search filter description
    self.searchFilterString = [NSString stringWithFormat:@"address \"%@\"", addressQuery];
    
    // handle search
	CLLocation * location = [self currentOrDefaultLocationToSearch];
	CLLocationCoordinate2D coord = location.coordinate;
    
	addressQuery = [self escapeStringForUrl:addressQuery];
	NSString * args = [NSString stringWithFormat:@"ll=%f,%f&spn=0.5,0.5&q=%@", coord.latitude, coord.longitude, addressQuery];

	[self requestPath:@"/maps/geo" withArgs:args searchType:OBASearchControllerSearchTypeAddress jsonDataSource:_googleMapsDataSource];
}

-(void) searchByPlacemark:(OBAPlacemark*)placemark {
	// Log the placemark
	[_appContext.activityListeners placemark:placemark];
	
    // request search
	CLLocationCoordinate2D location = placemark.coordinate;
    
	MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:location latRadius:kSearchRadius lonRadius:kSearchRadius];
	MKCoordinateSpan span = region.span;
	
    NSString * args = [NSString stringWithFormat:@"lat=%f&lon=%f&latSpan=%f&lonSpan=%f", location.latitude, location.longitude, span.latitudeDelta, span.longitudeDelta];
	
    [self requestPath:@"/api/where/stops-for-location.json" withArgs:args searchType:OBASearchControllerSearchTypePlacemark];
}

-(void) searchForAgenciesWithCoverage {
    // update search filter description
    self.searchFilterString = [NSString stringWithFormat:@"supported transit agencies"];
	
    // search
    [self requestPath:@"/api/where/agencies-with-coverage.json" withArgs:nil searchType:OBASearchControllerSearchTypeAgenciesWithCoverage];
   
}

- (void) requestPath:(NSString*)path withArgs:(NSString*)args searchType:(OBASearchControllerSearchType)searchType {
	[self requestPath:path withArgs:args searchType:searchType jsonDataSource:_obaDataSource];
}

- (void) requestPath:(NSString*)path withArgs:(NSString*)args searchType:(OBASearchControllerSearchType)searchType jsonDataSource:(OBAJsonDataSource*)jsonDataSource {
	@synchronized(self) {
		[_searchContext release];
        
		if( args )
			_searchContext = [[NSString alloc] initWithFormat:@"%@?%@",path,args];
		else
			_searchContext = [path retain];
		
		[jsonDataSource requestWithPath:path withArgs:args withDelegate:self context:_searchContext];
		
		[_progress setMessage:@"Connecting..." inProgress:TRUE progress:0];
	}
}

-(NSString*) progressCompleteMessageForSearchType {

	NSString * title = nil;
	
	switch (_searchType) {
		case OBASearchControllerSearchTypeNone:
			title = @"";
			break;
		case OBASearchControllerSearchTypeRegion:
		case OBASearchControllerSearchTypePlacemark:
		case OBASearchControllerSearchTypeStopId:			
		case OBASearchControllerSearchTypeRouteStops:
			title = @"Stops";
			break;
		case OBASearchControllerSearchTypeRoute:		
			title = @"Routes";
			break;
		case OBASearchControllerSearchTypeAddress:
			title = @"Places";
			break;
		case OBASearchControllerSearchTypeAgenciesWithCoverage:
			title = @"Agencies";
			break;
		default:			
			break;
	}
	
	return title;
}

-(void) handleSearchByLocationRegion:(id)jsonObject {
	[self fireStopsFromJsonObject:jsonObject];
}

-(void) handleSearchByRoute:(id)jsonObject {
	
	NSDictionary * data = [jsonObject valueForKey:@"data"];
	
	if( ! data || [data isEqual:[NSNull null]])
		return;
	
	NSArray * routesArray = [data valueForKey:@"routes"];
	
	if( ! routesArray )
		return;
	
	OBAModelFactory * modelFactory = _appContext.modelFactory;
	NSError * localError = nil;
	NSArray * routes = [modelFactory getRoutesFromJSONArray:routesArray error:&localError];
	
	if( localError ) {
		[self fireError:localError];
		return;
	}
	
	if( [routes count] == 1 ) {
		OBARoute * route = [routes objectAtIndex:0];
		OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchRouteStops:route.routeId];
		[self searchWithTarget: target];
	}
	else {
		OBASearchControllerResult * result = [OBASearchControllerResult result];
		result.routes = routes;
		[self fireUpdate:result];
	}
}

-(void) handleSearchByRouteStops:(id)jsonObject {
	
	NSDictionary * data = [jsonObject valueForKey:@"data"];
	
	if( ! data || [data isEqual:[NSNull null]])
		return;
	
	NSArray * stopsArray = [data objectForKey:@"stops"];
	
	if( stopsArray ) {
		OBAModelFactory * modelFactory = _appContext.modelFactory;
		NSError * localError = nil;	
		NSArray * newStops = [modelFactory getStopsFromJSONArray:stopsArray error:&localError];
		
		if( localError ) {
			[self fireError:localError];
			return;
		}
		
		
		[self fireStops:newStops limitExceeded:FALSE];
	}
}

-(void) handleSearchByStopId:(id)jsonObject {
	[self fireStopsFromJsonObject:jsonObject];
}

-(void) handleSearchByAddress:(id)jsonObject {
	
	if( ! jsonObject )
		return;
	
	OBAModelFactory * modelFactory = _appContext.modelFactory;
	NSError * localError = nil;
	NSArray * placemarks = [modelFactory getPlacemarksFromJSONObject:jsonObject error:&localError];
	
	if( localError ) {
		[self fireError:localError];
		return;
	}
	
	if( [placemarks count] == 1 ) {
		OBAPlacemark * placemark = [placemarks objectAtIndex:0];
		OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchPlacemark:placemark];
		[self searchWithTarget:target];
	}
	else {
		[self firePlacemarks:placemarks];
	}
}

-(void) handleSearchByPlacemark:(id)jsonObject {
	NSDictionary * data = [jsonObject valueForKey:@"data"];
	if( data == nil || [data isEqual:[NSNull null]] )
		return;
	NSArray * stopsArray = [data objectForKey:@"stops"];
	NSArray * stops = [self parseStops:stopsArray];
	NSNumber * limitExceeded = [data objectForKey:@"limitExceeded"];
	OBAPlacemark * placemark = [_target parameterForKey:kOBASearchControllerSearchArgumentParameter];
	NSArray * placemarks = [NSArray arrayWithObject:placemark];
	[self fireStops:stops placemarks:placemarks limitExceeded:[limitExceeded boolValue]];
}

-(void) handleSearchForAgenciesWithCoverage:(id)jsonObject {
	
	NSArray * data = [jsonObject objectForKey:@"data"];
	if( data == nil || [data isEqual:[NSNull null]] )
		return;
	
	OBAModelFactory * modelFactory = _appContext.modelFactory;
	NSError * localError = nil;
	NSArray * agenciesWithCoverage = [modelFactory getAgenciesWithCoverageFromJson:data error:&localError];
	
	if( localError ) {
		[self fireError:localError];
		return;
	}
	
	[self fireAgenciesWithCoverage:agenciesWithCoverage];
}

-(NSArray*) parseStops:(NSArray*)stopArray {
	
	OBAModelFactory * modelFactory = _appContext.modelFactory;
	NSError * localError = nil;	
	NSArray * newStops = [modelFactory getStopsFromJSONArray:stopArray error:&localError];
	
	if( localError ) {
		OBALogSevereWithError(localError,@"This is bad");
		[self fireError:localError];
		return [NSArray array];
	}
	
	newStops = [newStops sortedArrayUsingSelector:@selector(compareUsingName:)];
	
	return newStops;
}

-(void) fireStopsFromJsonObject:(id)jsonObject {
	NSDictionary * data = [jsonObject valueForKey:@"data"];
	if( data == nil || [data isEqual:[NSNull null]] )
		return;
	NSArray * stopsArray = [data objectForKey:@"stops"];
	NSArray * stops = [self parseStops:stopsArray];
	NSNumber * v = [data objectForKey:@"limitExceeded"];
	BOOL limitExceeded = [v boolValue];
	[self fireStops:stops limitExceeded:limitExceeded];
}

-(void) fireStops:(NSArray*)stops limitExceeded:(BOOL)limitExceeded {
	OBASearchControllerResult * result = [OBASearchControllerResult result];
	result.stops = stops;
	result.stopLimitExceeded = limitExceeded;
	[self fireUpdate:result];
}

-(void) firePlacemarks:(NSArray*)placemarks {
	OBASearchControllerResult * result = [OBASearchControllerResult result];
	result.placemarks = placemarks;
	[self fireUpdate:result];
}

-(void) fireStops:(NSArray*)stops placemarks:(NSArray*)placemarks limitExceeded:(BOOL)limitExceeded {
	OBASearchControllerResult * result = [OBASearchControllerResult result];
	result.stops = stops;
	result.placemarks = placemarks;
	result.stopLimitExceeded = limitExceeded;
	[self fireUpdate:result];
}

-(void ) fireAgenciesWithCoverage:(NSArray*)agenciesWithCoverage {
	OBASearchControllerResult * result = [OBASearchControllerResult result];
	result.agenciesWithCoverage = agenciesWithCoverage;
	[self fireUpdate:result];
}

-(void) fireUpdate:(OBASearchControllerResult*)result {
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

- (NSString*) escapeStringForUrl:(NSString*)url {
	url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSMutableString *escaped = [NSMutableString stringWithString:url];
	NSRange wholeString = NSMakeRange(0, [escaped length]);
	[escaped replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:wholeString];
	[escaped replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:wholeString];
	return escaped;
}

@end
