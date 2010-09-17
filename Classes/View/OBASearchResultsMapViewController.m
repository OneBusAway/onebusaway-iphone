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

#import "OBASearchResultsMapViewController.h"
#import "OBARoute.h"
#import "OBAStopAnnotation.h"
#import "OBAGenericAnnotation.h"
#import "OBAAgencyWithCoverage.h"
#import "OBANavigationTargetAnnotation.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBAUIKit.h"
#import "OBASearchViewController.h"
#import "OBAProgressIndicatorView.h"
#import "OBASearchResultsListViewController.h"
#import "OBAStopViewController.h"
#import "OBACoordinateBounds.h"
#import "OBASearchControllerImpl.h"


// Radius in meters
static const double kDefaultMapRadius = 100;
static const double kMaxMapDistanceFromCurrentLocation = 750;
static const double kPaddingScaleFactor = 1.1;
static const NSUInteger kShowNClosestStops = 4;


@interface OBASearchResultsMapViewController (Private)

- (void) refreshCurrentLocation;

- (void) reloadData;
- (CLLocation*) currentLocation;
- (UIImage*) getIconForStop:(OBAStop*)stop;

- (void) setAnnotationsFromResults;
- (void) setRegionFromResults;

- (MKCoordinateRegion) computeRegionForCurrentResults:(BOOL*)needsUpdate;
- (MKCoordinateRegion) computeRegionForStops:(NSArray*)stops;
- (MKCoordinateRegion) computeRegionForNClosestStops:(NSArray*)stops center:(CLLocation*)location numberOfStops:(NSUInteger)numberOfStops;
- (MKCoordinateRegion) computeRegionForPlacemarks:(NSArray*)stops;
- (MKCoordinateRegion) computeRegionForStops:(NSArray*)stops center:(CLLocation*)location;
- (MKCoordinateRegion) computeRegionForNearbyStops:(NSArray*)stops;
- (MKCoordinateRegion) computeRegionForPlacemarks:(NSArray*)placemarks andStops:(NSArray*)stops;
- (MKCoordinateRegion) computeRegionForAgenciesWithCoverage:(NSArray*)agenciesWithCoverage;

- (void) checkResults;
- (void) checkTooManyStopResults;
- (void) checkNoStopResults;
- (void) checkNoRouteResults;
- (void) checkNoPlacemarksResults;

@end


@implementation OBASearchResultsMapViewController

- (id) initWithApplicationContext:(OBAApplicationContext*)context {
	
	if( self = [super init] ) {
		
		_appContext = [context retain];
		
		_searchController = [[OBASearchControllerImpl alloc] initWithAppContext:context];
		_searchController.delegate = self;
		
		UIImage * a = [UIImage imageNamed:@"SegmentedControl-CrossHairs.png"];
		UIImage * b = [UIImage imageNamed:@"SegmentedControl-Region.png"];
		NSArray * items = [NSArray arrayWithObjects:a,b,nil];
		
		_searchTypeControl = [[UISegmentedControl alloc] initWithItems:items];
		_searchTypeControl.segmentedControlStyle = UISegmentedControlStyleBar;
		_searchTypeControl.momentary = TRUE;

		[_searchTypeControl addTarget:self action:@selector(onSearchTypeController:) forControlEvents:UIControlEventValueChanged];
		
		UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithCustomView:_searchTypeControl];
		[self.navigationItem setLeftBarButtonItem:item];
		[item release];
		
		self.navigationItem.titleView = [OBAProgressIndicatorView viewFromNibWithSource:_searchController.progress];
		
		_listButton = [[UIBarButtonItem alloc] initWithTitle:@"List" style:UIBarButtonItemStyleBordered target:self action:@selector(onListButton:)];
		[self.navigationItem setRightBarButtonItem:_listButton];
		_listButton.enabled = FALSE;
		
		_busStopIcons = [[NSMutableDictionary alloc] init];
		
		NSArray * directionIds = [NSArray arrayWithObjects:@"N",@"NE",@"E",@"SE",@"S",@"SW",@"W",@"NW",nil];
		
		for( int i=0; i<[directionIds count]; i++) {
			NSString * key = [directionIds objectAtIndex:i];
			NSString * imageName = [NSString stringWithFormat:@"BusStopIcon%@.png",key];
			UIImage * image = [UIImage imageNamed:imageName];
			[_busStopIcons setObject:image forKey:key];
		}
		
		_busImage = [[UIImage imageNamed: @"BusMapIcon.png" ] retain];
		_locationAnnotation = nil;
	}
	
	return self;
}

-(void) dealloc {
	
	[_appContext release];
	[_context release];
	
	[_searchController release];
	[_mapView release];
	[_listButton release];
	
	[_busStopIcons release];
	[_busImage release];
	
	[_searchTypeControl release];
	[_locationAnnotation release];
	
	[super dealloc];
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	[super loadView];
	
	_mapView = [[MKMapView alloc]initWithFrame:CGRectMake(0.0, 0.0, 120, 180)];
	
	// Center our map on our most recent location, or a default if not present
	CLLocationCoordinate2D defaultCenter = {0,0};
	MKCoordinateRegion region = MKCoordinateRegionMake(defaultCenter,MKCoordinateSpanMake(180, 180));

	OBAModelDAO * modelDao = _appContext.modelDao;
	CLLocation * mostRecentLocation = modelDao.mostRecentLocation;
	
	if( mostRecentLocation )
		region = [OBASphericalGeometryLibrary createRegionWithCenter:mostRecentLocation.coordinate latRadius:kDefaultMapRadius lonRadius:kDefaultMapRadius];
	
	region = [_mapView regionThatFits:region];
	_mapView.region = region;
	
	self.view = _mapView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	//[self reloadData];
	_mapView.delegate = self;
	[_appContext.locationManager addDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	NSLog(@"View will dissapear");
	_mapView.delegate = nil;
	

	[_appContext.locationManager removeDelegate:self];
}

#pragma mark OBASearchControllerDelegate Methods

- (void) handleSearchControllerUpdate:(OBASearchControllerResult*)result {
	[self reloadData];
}

#pragma mark OBALocationManagerDelegate Methods

- (void) locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location {
	[self refreshCurrentLocation];
}

#pragma mark MKMapViewDelegate Methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
	
	if( [annotation isKindOfClass:[OBAStop class]] ) {
		
		OBAStop * stop = (OBAStop*)annotation;
		static NSString * viewId = @"StopView";
		
		MKAnnotationView * view = [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
		if( view == nil ) {
			view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
		}
		view.canShowCallout = TRUE;
		view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		view.image = [self getIconForStop:stop];
		return view;
	}
	else if( [annotation isKindOfClass:[OBAPlacemark class]] ) {
		static NSString * viewId = @"NavigationTargetView";
		MKPinAnnotationView * view = (MKPinAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
		if( view == nil ) {
			view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
		}
		
		view.canShowCallout = TRUE;
		
		if( _searchController.searchType == OBASearchControllerSearchTypeAddress)
			view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		else
			view.rightCalloutAccessoryView = nil;
		return view;
	}
	else if( [annotation isKindOfClass:[OBANavigationTargetAnnotation class]] ) {
		static NSString * viewId = @"NavigationTargetView";
		MKPinAnnotationView * view = (MKPinAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
		if( view == nil ) {
			view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
		}
		
		OBANavigationTargetAnnotation * nav = annotation;
		
		view.canShowCallout = TRUE;
		
		if( nav.target )
			view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		else
			view.rightCalloutAccessoryView = nil;
		
		return view;
	}
	else if( [annotation isKindOfClass:[OBAGenericAnnotation class]] ) {
		
		OBAGenericAnnotation * ga = annotation;
		if( [@"currentLocation" isEqual:ga.context] ) {
			static NSString * viewId = @"CurrentLocationView";
			
			MKAnnotationView * view = [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
			if( view == nil ) {
				view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
			}
			view.canShowCallout = FALSE;
			view.image = [UIImage imageNamed:@"BlueMarker.png"];
			return view;
		}
	}
	
	return nil;
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	
	id annotation = view.annotation;
	
	if( [annotation isKindOfClass:[OBAStop class] ] ) {		
		OBAStop * stop = annotation;
		OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationContext:_appContext stop:stop];
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
	else if( [annotation isKindOfClass:[OBAPlacemark class]] ) {
		OBAPlacemark * placemark = annotation;
		OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchPlacemark:placemark];
		[_searchController searchWithTarget:target];
	}
}

-(IBAction) onSearchTypeController:(id)sender {
	switch(_searchTypeControl.selectedSegmentIndex) {
		case 0: {
			OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchCurrentLocation];
			[_searchController searchWithTarget:target];
			break;
		}
		case 1:{
			OBANavigationTarget * target = [OBASearchControllerFactory getNavigationTargetForSearchLocationRegion:_mapView.region];
			[_searchController searchWithTarget:target];
			break;
		}
	}
}

-(IBAction) onListButton:(id)sender {
	OBASearchControllerResult * result = _searchController.result;
	if( result ) {
		OBASearchResultsListViewController * vc = [[OBASearchResultsListViewController alloc] initWithContext:_appContext searchControllerResult:result];
		[self.navigationController pushViewController:vc animated:TRUE];
	}
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return [_searchController getSearchTarget];
}

-(void) setNavigationTarget:(OBANavigationTarget*)target {
	[_searchController searchWithTarget:target];
}

@end


#pragma mark OBASearchMapViewController Private Methods

@implementation OBASearchResultsMapViewController (Private)

- (void) refreshCurrentLocation {
	
	NSLog(@"Refresh Location");
	OBALocationManager * lm = _appContext.locationManager;
	CLLocation * location = lm.currentLocation;
	
	if( _locationAnnotation ) {
		[_mapView removeAnnotation:_locationAnnotation];
		[_locationAnnotation release];
		_locationAnnotation = nil;
	}
	
	if( location ) {
		_locationAnnotation = [[OBAGenericAnnotation alloc] initWithTitle:nil subtitle:nil coordinate:location.coordinate context:@"currentLocation"];
		[_mapView addAnnotation:_locationAnnotation];
	}
}

- (void) reloadData {

	OBASearchControllerResult * result = _searchController.result;
	_listButton.enabled = (result != nil);
	
	if( result && result.searchType == OBASearchControllerSearchTypeRoute && [result.routes count] > 0) {
		[self performSelector:@selector(onListButton:) withObject:self afterDelay:1];
		return;
	 }
	
	[self refreshCurrentLocation];
	[self setAnnotationsFromResults];
	[self setRegionFromResults];
	
	[self checkResults];
}

- (UIImage*) getIconForStop:(OBAStop*)stop {
	
	if( ! stop.direction )
		return _busImage;
	
	UIImage * image = [_busStopIcons objectForKey:stop.direction];
	
	if( ! image || [image isEqual:[NSNull null]] )
		return nil;
	
	return image;
}

- (CLLocation*) currentLocation {
	
	OBALocationManager * lm = _appContext.locationManager;
	CLLocation * location = lm.currentLocation;
	
	if( ! location )
		location = _searchController.searchLocation;

	if( ! location ) {
		CLLocationCoordinate2D center = _mapView.centerCoordinate;	
		location = [[[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude] autorelease];	
	}
	
	return location;
}

- (void) setAnnotationsFromResults {
	
	[_mapView removeAnnotations:_mapView.annotations];	
	
	NSMutableArray * annotations = [[NSMutableArray alloc] init];
	
	if( _locationAnnotation )
		[annotations addObject:_locationAnnotation];
	
	OBASearchControllerResult * result = _searchController.result;
	
	if( result ) {
		
		[annotations addObjectsFromArray:result.stops];
		[annotations addObjectsFromArray:result.placemarks];
		
		for( OBAAgencyWithCoverage * agencyWithCoverage in result.agenciesWithCoverage ) {
			OBAAgency * agency = agencyWithCoverage.agency;
			OBANavigationTargetAnnotation * an = [[OBANavigationTargetAnnotation alloc] initWithTitle:agency.name subtitle:nil coordinate:agencyWithCoverage.coordinate target:nil];
			[annotations addObject:an];
			[an release];
		}
		
		[annotations addObjectsFromArray:result.agenciesWithCoverage];
	}
	
	[_mapView addAnnotations:annotations];
	[annotations release];
}

void dumpRegion(MKCoordinateRegion r) {
	CLLocationCoordinate2D c = r.center;
	MKCoordinateSpan span = r.span;
	NSLog(@"Min + Max Corners");
	NSLog(@"%f %f",c.latitude - span.latitudeDelta/2,c.longitude - span.longitudeDelta/2);
	NSLog(@"%f %f",c.latitude + span.latitudeDelta/2,c.longitude + span.longitudeDelta/2);	
	NSLog(@"Box");
	NSLog(@"%f %f",c.latitude - span.latitudeDelta/2,c.longitude - span.longitudeDelta/2);
	NSLog(@"%f %f",c.latitude + span.latitudeDelta/2,c.longitude - span.longitudeDelta/2);	
	NSLog(@"%f %f",c.latitude + span.latitudeDelta/2,c.longitude + span.longitudeDelta/2);
	NSLog(@"%f %f",c.latitude - span.latitudeDelta/2,c.longitude + span.longitudeDelta/2);	
	NSLog(@"%f %f",c.latitude - span.latitudeDelta/2,c.longitude - span.longitudeDelta/2);
}

- (void) setRegionFromResults {
	
	BOOL needsUpdate = FALSE;
	MKCoordinateRegion region = [self computeRegionForCurrentResults:&needsUpdate];
	if( needsUpdate ) {
		dumpRegion(region);
		[_mapView setRegion:region animated:YES];
		dumpRegion(_mapView.region);
	}
}


- (MKCoordinateRegion) computeRegionForCurrentResults:(BOOL*)needsUpdate {
	
	*needsUpdate = TRUE;
	
	OBASearchControllerResult * result = _searchController.result;
	
	if( ! result ) {
		CLLocation * center = [self currentLocation];
		if( center ) {
			return [OBASphericalGeometryLibrary createRegionWithCenter:center.coordinate latRadius:kDefaultMapRadius lonRadius:kDefaultMapRadius];
		}
		else {
			*needsUpdate = FALSE;
			return _mapView.region;
		}
	}
	
	switch(result.searchType) {
		case OBASearchControllerSearchTypeCurrentLocation:
		case OBASearchControllerSearchTypeStopId:
			return [self computeRegionForNClosestStops:result.stops center:[self currentLocation] numberOfStops:kShowNClosestStops];
		case OBASearchControllerSearchTypeRoute:
		case OBASearchControllerSearchTypeRouteStops:	
			return [self computeRegionForNearbyStops:result.stops];
		case OBASearchControllerSearchTypePlacemark:
			return [self computeRegionForPlacemarks:result.placemarks andStops:result.stops];
		case OBASearchControllerSearchTypeAddress:
			return [self computeRegionForPlacemarks:result.placemarks];
		case OBASearchControllerSearchTypeAgenciesWithCoverage:
			return [self computeRegionForAgenciesWithCoverage:result.agenciesWithCoverage];
		case OBASearchControllerSearchTypeNone:
		case OBASearchControllerSearchTypeRegion:
		default:
			*needsUpdate = FALSE;
			return _mapView.region;
	}
}

- (MKCoordinateRegion) computeRegionForStops:(NSArray*)stops {
	return [self computeRegionForStops:stops center:[self currentLocation]];
}

NSInteger sortStopsByDistanceFromLocation(id o1, id o2, void *context) {
	
	OBAStop * stop1 = (OBAStop*) o1;
	OBAStop * stop2 = (OBAStop*) o2;
	CLLocation * location = (CLLocation*)context;
	
	CLLocation * stopLocation1 = [[CLLocation alloc] initWithLatitude:stop1.lat longitude:stop1.lon];
	CLLocation * stopLocation2 = [[CLLocation alloc] initWithLatitude:stop2.lat longitude:stop2.lon];
	
	double v1 = [location getDistanceFrom:stopLocation1];
	double v2 = [location getDistanceFrom:stopLocation2];
	
	[stopLocation1 release];
	[stopLocation2 release];
	
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;	
}

- (MKCoordinateRegion) computeRegionForNClosestStops:(NSArray*)stops center:(CLLocation*)location numberOfStops:(NSUInteger)numberOfStops {
	NSMutableArray * stopsSortedByDistance = [NSMutableArray arrayWithArray:stops];
	NSLog(@"Sorting...");
	[stopsSortedByDistance sortUsingFunction:sortStopsByDistanceFromLocation context:location];
	NSLog(@"Sorting complete");
	while( [stopsSortedByDistance count] > numberOfStops )
		[stopsSortedByDistance removeLastObject];
	for( OBAStop * stop in stopsSortedByDistance )
		NSLog(@"  stop=%@", stop.stopId);
	return [self computeRegionForStops:stopsSortedByDistance center:location];
}

- (MKCoordinateRegion) computeRegionForStops:(NSArray*)stops center:(CLLocation*)location {
	
	CLLocationCoordinate2D center = location.coordinate;
	
	MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:center latRadius:kDefaultMapRadius lonRadius:kDefaultMapRadius];
	MKCoordinateSpan span = region.span;
	
	for( OBAStop * stop in stops ) {
		double latDelta = ABS(stop.lat - center.latitude) * 2 * kPaddingScaleFactor;
		double lonDelta = ABS(stop.lon - center.longitude) * 2 * kPaddingScaleFactor;
		span.latitudeDelta =  MAX(span.latitudeDelta,latDelta);
		span.longitudeDelta =  MAX(span.longitudeDelta,lonDelta);
	}
	
	region.center = center;
	region.span = span;
	
	return region;
}

- (MKCoordinateRegion) computeRegionForNearbyStops:(NSArray*)stops {
	
	NSMutableArray * stopsInRange = [NSMutableArray array];
	CLLocation * center = [self currentLocation];
	
	for( OBAStop * stop in stops) {
		CLLocation * location = [[CLLocation alloc] initWithLatitude:stop.lat longitude:stop.lon];
		double d = [location getDistanceFrom:center];
		if( d < kMaxMapDistanceFromCurrentLocation )
			[stopsInRange addObject:stop];
		[location release];
	}
	
	if( [stopsInRange count] > 0)
		return [self computeRegionForStops:stopsInRange];
	else
		return [self computeRegionForStops:stops];
}

- (MKCoordinateRegion) computeRegionForPlacemarks:(NSArray*)placemarks {
	
	OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
	
	for( OBAPlacemark * placemark in placemarks )
		[bounds addCoordinate:placemark.coordinate];
	
	if( bounds.empty )
		return _mapView.region;
	
	return bounds.region;
}

- (MKCoordinateRegion) computeRegionForPlacemarks:(NSArray*)placemarks andStops:(NSArray*)stops {
	
	CLLocation * center = [self currentLocation];
	
	for( OBAPlacemark * placemark in placemarks ) {
		CLLocationCoordinate2D coordinate = placemark.coordinate;
		center = [[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude] autorelease];
	}
	
	return [self computeRegionForNClosestStops:stops center:center numberOfStops:kShowNClosestStops];
}

- (MKCoordinateRegion) computeRegionForAgenciesWithCoverage:(NSArray*)agenciesWithCoverage {
	if( [agenciesWithCoverage count] == 0 )
		return _mapView.region;
	
	OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
	
	for( OBAAgencyWithCoverage * agencyWithCoverage in agenciesWithCoverage )
		[bounds addCoordinate:agencyWithCoverage.coordinate];
	
	if( bounds.empty )
		return _mapView.region;
	
	MKCoordinateRegion region = bounds.region;
	
	MKCoordinateRegion minRegion = [OBASphericalGeometryLibrary createRegionWithCenter:region.center latRadius:50000 lonRadius:50000];
	
	if( region.span.latitudeDelta < minRegion.span.latitudeDelta )
		region.span.latitudeDelta = minRegion.span.latitudeDelta;
	
	if( region.span.longitudeDelta < minRegion.span.longitudeDelta )
		region.span.longitudeDelta = minRegion.span.longitudeDelta;
	
	return region;
}

- (void) checkResults {
	
	OBASearchControllerResult * result = _searchController.result;
	if( ! result )
		return;
	
	switch (result.searchType) {
		case OBASearchControllerSearchTypeCurrentLocation:
		case OBASearchControllerSearchTypeRegion:
		case OBASearchControllerSearchTypeStopId:
		case OBASearchControllerSearchTypePlacemark:
			[self checkNoStopResults];
			[self checkTooManyStopResults];
			break;
		case OBASearchControllerSearchTypeRoute:
			[self checkNoRouteResults];
			break;
		case OBASearchControllerSearchTypeAddress:
			[self checkNoPlacemarksResults];
			break;
		default:
			break;
	}
}

- (void) checkTooManyStopResults {
	OBASearchControllerResult * result = _searchController.result;
	if( result && result.stopLimitExceeded ) {
		result.stopLimitExceeded = FALSE;
		UIAlertView * view = [[UIAlertView alloc] init];
		view.title = @"Too many stops";
		view.message = @"There are too many stops to display all of them.  Try zooming in and redoing your search.";
		[view addButtonWithTitle:@"Ok"];
		view.cancelButtonIndex = 0;
		[view show];
	}	
}

- (void) checkNoStopResults {
	OBASearchControllerResult * result = _searchController.result;
	if( [result.stops count] == 0 ) {
		_listButton.enabled = FALSE;
		UIAlertView * view = [[UIAlertView alloc] init];
		view.title = @"No stops found";
		view.message = @"No stops were found for your search.  See the list of supported transit agencies for service coverage.";
		view.delegate = self;
		[view addButtonWithTitle:@"Agencies"];
		[view addButtonWithTitle:@"Ok"];
		view.cancelButtonIndex = 1;
		[view show];
	}
}

- (void) checkNoRouteResults {
	OBASearchControllerResult * result = _searchController.result;
	if( [result.routes count] == 0 ) {
		_listButton.enabled = FALSE;
		UIAlertView * view = [[UIAlertView alloc] init];
		view.title = @"No routes found";
		view.message = @"No routes were found for your search.  See the list of supported transit agencies for service coverage.";
		view.delegate = self;
		[view addButtonWithTitle:@"Agencies"];
		[view addButtonWithTitle:@"Ok"];
		view.cancelButtonIndex = 1;
		[view show];
	}
}

- (void) checkNoPlacemarksResults {
	OBASearchControllerResult * result = _searchController.result;
	if( [result.placemarks count] == 0 ) {
		_listButton.enabled = FALSE;
		UIAlertView * view = [[UIAlertView alloc] init];
		view.title = @"No places found";
		view.message = @"No places were found for your search.  See the list of supported transit agencies for service coverage.";
		view.delegate = self;
		[view addButtonWithTitle:@"Agencies"];
		[view addButtonWithTitle:@"Ok"];
		view.cancelButtonIndex = 1;
		[view show];
	}
}

@end

