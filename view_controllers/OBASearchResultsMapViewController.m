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
#import "OBAStopV2.h"
#import "OBARouteV2.h"
#import "OBAAgencyWithCoverageV2.h"
#import "OBAGenericAnnotation.h"
#import "OBAAgencyWithCoverage.h"
#import "OBANavigationTargetAnnotation.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBAProgressIndicatorView.h"
#import "OBASearchResultsListViewController.h"
#import "OBABookmarksViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBAStopViewController.h"
#import "OBACoordinateBounds.h"
#import "OBALogger.h"
#import "OBAStopIconFactory.h"
#import "OBAPresentation.h"
#import "OBAInfoViewController.h"
#import <QuartzCore/QuartzCore.h>

#define kScopeViewAnimationDuration 0.25
#define kRouteSegmentIndex 0
#define kAddressSegmentIndex 1
#define kStopNumberSegmentIndex 2
#define kMapLabelAnimationDuration 0.25

// Radius in meters
static const double kDefaultMapRadius = 100;
static const double kMinMapRadius = 150;
static const double kMaxLatDeltaToShowStops = 0.008;
static const double kRegionScaleFactor = 1.5;
static const double kMinRegionDeltaToDetectUserDrag = 50;

static const double kRegionChangeRequestsTimeToLive = 3.0;

static const double kMaxMapDistanceFromCurrentLocationForNearby = 800;
static const double kPaddingScaleFactor = 1.075;
static const NSUInteger kShowNClosestStops = 4;

static const double kStopsInRegionRefreshDelayOnDrag = 0.1;
static const double kStopsInRegionRefreshDelayOnLocate = 0.1;

@interface OBASearchResultsMapViewController ()
@property BOOL hideFutureNetworkErrors;
@property MKCoordinateRegion mostRecentRegion;
@property(strong) CLLocation *mostRecentLocation;
@property(strong) NSTimer *refreshTimer;
@property(strong) OBANetworkErrorAlertViewDelegate *networkErrorAlertViewDelegate;
@property(strong) OBAMapRegionManager *mapRegionManager;
@property(strong) OBASearchController *searchController;
@property(strong) UIView *activityIndicatorWrapper;
@property(strong) UIActivityIndicatorView * activityIndicatorView;
@property(strong) UIButton *locationButton;
@property(strong) UIBarButtonItem *listBarButtonItem;
@property(strong) OBASearchResultsListViewController *searchResultsListViewController;
@property (nonatomic) BOOL secondSearchTry;
@property (strong) OBANavigationTarget *savedNavigationTarget;
@property (nonatomic) UIView *titleView;
@end

@interface OBASearchResultsMapViewController (Private)

- (void)refreshCurrentLocation;

- (void)scheduleRefreshOfStopsInRegion:(NSTimeInterval)interval location:(CLLocation*)location;
- (NSTimeInterval)getRefreshIntervalForLocationAccuracy:(CLLocation*)location;
- (void)refreshStopsInRegion;
- (void)refreshSearchToolbar;

- (void)reloadData;
- (CLLocation*)currentLocation;

- (void)showLocationServicesAlert;

- (void)didCompleteNetworkRequest;

- (void)setAnnotationsFromResults;
- (void)setOverlaysFromResults;
- (void)setRegionFromResults;

- (NSString*)computeSearchFilterString;
- (NSString*)computeLabelForCurrentResults;
- (void) applyMapLabelWithText:(NSString*)labelText;

- (MKCoordinateRegion)computeRegionForCurrentResults:(BOOL*)needsUpdate;
- (MKCoordinateRegion)computeRegionForStops:(NSArray*)stops;
- (MKCoordinateRegion)computeRegionForNClosestStops:(NSArray*)stops center:(CLLocation*)location numberOfStops:(NSUInteger)numberOfStops;
- (MKCoordinateRegion)computeRegionForPlacemarks:(NSArray*)stops;
- (MKCoordinateRegion)computeRegionForStops:(NSArray*)stops center:(CLLocation*)location;
- (MKCoordinateRegion)computeRegionForNearbyStops:(NSArray*)stops;
- (MKCoordinateRegion)computeRegionForPlacemarks:(NSArray*)placemarks andStops:(NSArray*)stops;
- (MKCoordinateRegion)computeRegionForAgenciesWithCoverage:(NSArray*)agenciesWithCoverage;
- (MKCoordinateRegion)getLocationAsRegion:(CLLocation*)location;

- (void)checkResults;
- (BOOL)checkOutOfRangeResults;
- (void)checkNoRouteResults;
- (void)checkNoPlacemarksResults;
- (void)checkNoStopIdResults;

- (void)showNoResultsAlertWithTitle:(NSString*)title prompt:(NSString*)prompt;

- (void)cancelPressed;
- (BOOL)controllerIsVisibleAndActive;
- (BOOL)outOfServiceArea;

- (CLLocationDistance)getDistanceFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end;
- (CLRegion*)convertVisibleMapIntoCLRegion;

- (BOOL)checkStopsInRegion;
@end

@implementation OBASearchResultsMapViewController

- (id)init {
    self = [super initWithNibName:@"OBASearchResultsMapViewController" bundle:nil];
    
    if (self) {
        self.title = NSLocalizedString(@"Map", @"Map tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"CrossHairs"];
    }
    return self;
}

- (void) dealloc {
    [self.searchController cancelOpenConnections];
}

- (void) viewDidLoad {
    [super viewDidLoad];

    self.networkErrorAlertViewDelegate = [[OBANetworkErrorAlertViewDelegate alloc] initWithContext:self.appDelegate];

    CGRect indicatorBounds = CGRectMake(12, 12, 36, 36);
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        indicatorBounds.origin.y += self.navigationController.navigationBar.frame.size.height +
        [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    self.activityIndicatorWrapper = [[UIView alloc] initWithFrame:indicatorBounds];
    self.activityIndicatorWrapper.backgroundColor = OBARGBACOLOR(0, 0, 0, 0.5);
    self.activityIndicatorWrapper.layer.cornerRadius = 4.f;
    self.activityIndicatorWrapper.layer.shouldRasterize = YES;
    self.activityIndicatorWrapper.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.activityIndicatorWrapper.hidden = YES;

    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectInset(self.activityIndicatorWrapper.bounds, 4, 4)];
    self.activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    [self.activityIndicatorWrapper addSubview:self.activityIndicatorView];
    [self.view addSubview:self.activityIndicatorWrapper];

    CLLocationCoordinate2D p = {0,0};
    self.mostRecentRegion = MKCoordinateRegionMake(p, MKCoordinateSpanMake(0,0));
    
    self.refreshTimer = nil;
    
    self.mapRegionManager = [[OBAMapRegionManager alloc] initWithMapView:self.mapView];
    self.mapRegionManager.lastRegionChangeWasProgramatic = YES;
    
    self.hideFutureNetworkErrors = NO;
    
    self.filterToolbar = [[OBASearchResultsMapFilterToolbar alloc] initWithDelegate:self andappDelegate:self.appDelegate];
    
    self.searchController = [[OBASearchController alloc] initWithappDelegate:self.appDelegate];
    self.searchController.delegate = self;
    self.searchController.progress.delegate = self;
    if (self.savedNavigationTarget) {
        [self.searchController searchWithTarget:self.savedNavigationTarget];
        self.savedNavigationTarget = nil;
    }
    
    self.navigationItem.leftBarButtonItem = [self getArrowButton];


    self.listBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"lines"] style:UIBarButtonItemStyleBordered target:self action:@selector(showListView:)];
    self.listBarButtonItem.accessibilityLabel = NSLocalizedString(@"Nearby stops list", @"self.listBarButtonItem.accessibilityLabel");
    self.navigationItem.rightBarButtonItem = self.listBarButtonItem;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        self.searchBar.barTintColor = [UIColor clearColor];
        [self.titleView addSubview:self.searchBar];
        self.navigationItem.titleView = self.titleView;
    } else {
        self.navigationItem.titleView = self.searchBar;
    }

    self.mapLabel.hidden = YES;
    self.mapLabel.alpha = 0;

    CALayer *labelLayer = self.mapLabel.layer;
    labelLayer.rasterizationScale = [UIScreen mainScreen].scale;
    labelLayer.shouldRasterize = YES;
    labelLayer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9].CGColor;
    labelLayer.cornerRadius = 7;

    labelLayer.shadowColor = [UIColor blackColor].CGColor;
    labelLayer.shadowOpacity = 0.2;
    labelLayer.shadowOffset = CGSizeMake(0,0);
    labelLayer.shadowRadius = 7;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        CGRect mapLabelFrame = self.mapLabel.frame;
        mapLabelFrame.origin.y += self.navigationController.navigationBar.frame.size.height +
        [UIApplication sharedApplication].statusBarFrame.size.height;
        self.mapLabel.frame = mapLabelFrame;
    }
}

- (void)onFilterClear {
    [self.filterToolbar hideWithAnimated:YES];
    [self refreshStopsInRegion];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCompleteNetworkRequest) name:OBAApplicationDidCompleteNetworkRequestNotification object:nil];

    OBALocationManager * lm = self.appDelegate.locationManager;
    [lm addDelegate:self];
    [lm startUpdatingLocation];
    self.navigationItem.leftBarButtonItem.enabled = lm.locationServicesEnabled;

    [self refreshSearchToolbar];
    if (self.searchController.unfilteredSearch) {
        [self refreshStopsInRegion];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OBAApplicationDidCompleteNetworkRequestNotification object:nil];
    
    [self.appDelegate.locationManager stopUpdatingLocation];
    [self.appDelegate.locationManager removeDelegate:self];

    [self.filterToolbar hideWithAnimated:NO];
}

- (UIBarButtonItem *)getArrowButton {
    UIBarButtonItem *arrowButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"lbs_arrow"] style:UIBarButtonItemStyleBordered target:self action:@selector(onCrossHairsButton:)];
    arrowButton.accessibilityLabel = NSLocalizedString(@"my location", @"arrowButton.accessibilityLabel");
    arrowButton.accessibilityHint = NSLocalizedString(@"centers the map on current location", @"arrowButton.accessibilityHint");
    return arrowButton;
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    [searchBar setShowsCancelButton:YES animated:YES];
    [self applyMapLabelWithText:nil];
    [self animateInScopeView];
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    [self.navigationItem setRightBarButtonItem:self.listBarButtonItem animated:YES];
    [self.navigationItem setLeftBarButtonItem:[self getArrowButton] animated:YES];
    [searchBar setShowsCancelButton:NO animated:YES];
    [self animateOutScopeView];

    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar endEditing:YES];
    [self cancelPressed];

}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    OBANavigationTarget* target = nil;
    self.searchController.searchRegion = [self convertVisibleMapIntoCLRegion];
    if (kRouteSegmentIndex == self.searchTypeSegmentedControl.selectedSegmentIndex) {
        target = [OBASearch getNavigationTargetForSearchRoute:searchBar.text];
    }
    else if (kAddressSegmentIndex == self.searchTypeSegmentedControl.selectedSegmentIndex) {
        target = [OBASearch getNavigationTargetForSearchAddress:searchBar.text];
    }
    else {
        target = [OBASearch getNavigationTargetForSearchStopCode:searchBar.text];
    }

    [self.appDelegate navigateToTarget:target];
    [searchBar endEditing:YES];
    
}

- (void)animateInScopeView {
    CGRect offscreenScopeFrame = self.scopeView.frame;
    offscreenScopeFrame.origin.y = -offscreenScopeFrame.size.height;
    self.scopeView.frame = offscreenScopeFrame;
    [self.view addSubview:self.scopeView];
    
    CGRect finalScopeFrame = self.scopeView.frame;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        finalScopeFrame.origin.y = self.navigationController.navigationBar.frame.size.height +
                                    [UIApplication sharedApplication].statusBarFrame.size.height;
    } else {
        finalScopeFrame.origin.y = 0;
    }
    
    [UIView animateWithDuration:kScopeViewAnimationDuration animations:^{
        self.scopeView.frame = finalScopeFrame;
    }];
}

- (void)animateOutScopeView {
    CGRect offscreenScopeFrame = self.scopeView.frame;
    offscreenScopeFrame.origin.y = -offscreenScopeFrame.size.height;
    
    [UIView animateWithDuration:kScopeViewAnimationDuration animations:^{
        self.scopeView.frame = offscreenScopeFrame;
    } completion:^(BOOL finished) {
        [self.scopeView removeFromSuperview];
    }];
}

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget*)navigationTarget {
    if (OBASearchTypeRegion == self.searchController.searchType) {
        return [OBASearch getNavigationTargetForSearchLocationRegion:self.mapView.region];
    }
    else {
        return [self.searchController getSearchTarget];
    }
}

-(void) setNavigationTarget:(OBANavigationTarget*)target {
    
    OBASearchType searchType = [OBASearch getSearchTypeForNagivationTarget:target];

    if (OBASearchTypeRegion == searchType) {
        [self.searchController searchPending];
        
        NSDictionary * parameters = target.parameters;
        NSData * data = parameters[kOBASearchControllerSearchArgumentParameter];
        MKCoordinateRegion region;
        [data getBytes:&region];
        [self.mapRegionManager setRegion:region changeWasProgramatic:NO];
    }
    else {
        if (self.searchController) {
            [self.searchController searchWithTarget:target];
        } else {
            self.savedNavigationTarget = target;
        }
    }

    [self refreshSearchToolbar];
}

#pragma mark - OBASearchControllerDelegate Methods

- (void)handleSearchControllerStarted:(OBASearchType)searchType {
    if (OBASearchTypeNone != searchType && OBASearchTypeRegion != searchType) {
        self.mapRegionManager.lastRegionChangeWasProgramatic = NO;
    }
}

- (void)handleSearchControllerUpdate:(OBASearchResult*)result {
    self.secondSearchTry = NO;
    [self reloadData];
}

- (void)handleSearchControllerError:(NSError*)error {
    // We get this message because the user clicked "Don't allow" on using the current location.  Unfortunately,
    // this error gets propagated to us when the app isn't active (because the alert asking about location is).

    if (kCLErrorDomain == error.domain && kCLErrorDenied == error.code) {
        [self showLocationServicesAlert];
        return;
    }
    
    if (!self.controllerIsVisibleAndActive) {
        return;
    }
    if (!self.secondSearchTry) {
        self.secondSearchTry = YES;
        [self.searchController searchWithTarget:[self.searchController getSearchTarget]];
        return;
    }
    if ([error.domain isEqual:NSURLErrorDomain] || [error.domain isEqual:NSPOSIXErrorDomain]) {
        
        // We hide repeated network errors
        if (self.hideFutureNetworkErrors) {
            return;
        }
        
        self.hideFutureNetworkErrors = YES;
        self.navigationItem.title = NSLocalizedString(@"Error connecting",@"self.navigationItem.title");
        
        UIAlertView * view = [[UIAlertView alloc] init];
        view.tag = 1;
        view.title = NSLocalizedString(@"Error connecting",@"self.navigationItem.title");
        view.message = NSLocalizedString(@"There was a problem with your Internet connection.\r\n\r\nPlease check your network connection or contact us if you think the problem is on our end.",@"view.message");
        view.delegate = self.networkErrorAlertViewDelegate;
        [view addButtonWithTitle:NSLocalizedString(@"Contact Us",@"view addButtonWithTitle")];
        [view addButtonWithTitle:NSLocalizedString(@"Dismiss",@"view addButtonWithTitle")];
        view.cancelButtonIndex = 1;
        [view show];
    }
}

#pragma mark - OBALocationManagerDelegate Methods

- (void)locationManager:(OBALocationManager*)manager didUpdateLocation:(CLLocation*)location {
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [self refreshCurrentLocation];
}

- (void)locationManager:(OBALocationManager *)manager didFailWithError:(NSError*)error {
    if (kCLErrorDomain == error.domain && kCLErrorDenied == error.code) {
        [self showLocationServicesAlert];
    }
}

#pragma mark - OBAProgressIndicatorDelegate

- (void)progressUpdated {
    
    id<OBAProgressIndicatorSource> progress = self.searchController.progress;

    if (progress.inProgress) {
        self.activityIndicatorWrapper.hidden = NO;
        [self.activityIndicatorView startAnimating];
    }
    else {
        self.activityIndicatorWrapper.hidden = YES;
        [self.activityIndicatorView stopAnimating];
    }
}

#pragma mark MKMapViewDelegate Methods

- (void)mapView:(MKMapView *)aMapView didAddAnnotationViews:(NSArray *)views {
    for (MKAnnotationView *view in views) {
        if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
            [view.superview bringSubviewToFront:view];
            return;
        }
    }
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    [self.mapRegionManager mapView:mapView regionWillChangeAnimated:animated];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {

    if (mapView.userLocation) {
        UIView *annotationView = [mapView viewForAnnotation:mapView.userLocation];
        [annotationView.superview bringSubviewToFront:annotationView];
    }
    
    [self.mapRegionManager mapView:mapView regionDidChangeAnimated:animated];
    
    if (self.searchController.unfilteredSearch) {
        if (self.mapRegionManager.lastRegionChangeWasProgramatic) {
            OBALocationManager * lm = self.appDelegate.locationManager;
            double refreshInterval = [self getRefreshIntervalForLocationAccuracy:lm.currentLocation];
            [self scheduleRefreshOfStopsInRegion:refreshInterval location:lm.currentLocation];
        }
        else {
            [self scheduleRefreshOfStopsInRegion:kStopsInRegionRefreshDelayOnDrag location:nil];
        }
    }
    
    float scale = 1.0;
    float alpha = 1.0;
    
    OBASearchResult * result = self.searchController.result;
    
    if (result && OBASearchTypeRouteStops == result.searchType) {
        scale = [OBAPresentation computeStopsForRouteAnnotationScaleFactor:mapView.region];
        alpha = scale <= 0.11 ? 0.0 : 1.0;
    }
    
    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
    
    for (id<MKAnnotation> annotation in mapView.annotations) {
        if ([annotation isKindOfClass:[OBAStopV2 class]]) {
            MKAnnotationView * view = [mapView viewForAnnotation:annotation];
            view.transform = transform;
            view.alpha = alpha;
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {

    if ([annotation isKindOfClass:[OBAStopV2 class]]) {
        
        OBAStopV2 *stop = (OBAStopV2*)annotation;
        static NSString *viewId = @"StopView";
        
        MKAnnotationView * view = [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
        if (!view) {
            view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
        }
        view.canShowCallout = YES;
        UIButton *rightCalloutButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        rightCalloutButton.tintColor = OBAGREEN;
        view.rightCalloutAccessoryView = rightCalloutButton;
        
        OBASearchResult *result = self.searchController.result;
        
        if (result && OBASearchTypeRouteStops == result.searchType) {
            float scale = [OBAPresentation computeStopsForRouteAnnotationScaleFactor:mapView.region];
            float alpha = scale <= 0.11 ? 0.0 : 1.0;
            
            view.transform = CGAffineTransformMakeScale(scale, scale);
            view.alpha = alpha;
        }

        OBAStopIconFactory * stopIconFactory = self.appDelegate.stopIconFactory;
        view.image = [stopIconFactory getIconForStop:stop];
        return view;
    }
    else if ([annotation isKindOfClass:[OBAPlacemark class]]) {
        static NSString * viewId = @"NavigationTargetView";
        MKPinAnnotationView * view = (MKPinAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
        if (!view) {
            view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
        }
        
        view.canShowCallout = YES;

        if (OBASearchTypeAddress == self.searchController.searchType) {
            view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        else {
            view.rightCalloutAccessoryView = nil;
        }
        return view;
    }
    else if ([annotation isKindOfClass:[OBANavigationTargetAnnotation class]]) {
        static NSString * viewId = @"NavigationTargetView";
        MKPinAnnotationView * view = (MKPinAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
        if (!view) {
            view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
        }
        
        OBANavigationTargetAnnotation * nav = annotation;
        
        view.canShowCallout = YES;
        
        if (nav.target) {
            view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        else {
            view.rightCalloutAccessoryView = nil;
        }
        
        return view;
    }
    else if ([annotation isKindOfClass:[OBAGenericAnnotation class]]) {
        // TODO: verify that this is actually dead code. I am pretty sure this cannot be hit anymore.
        OBAGenericAnnotation * ga = annotation;
        if ([@"currentLocation" isEqual:ga.context]) {
            static NSString * viewId = @"CurrentLocationView";
            
            MKAnnotationView * view = [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
            if (!view) {
                view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
            }
            view.canShowCallout = NO;
            view.image = [UIImage imageNamed:@"BlueMarker.png"];
            return view;
        }
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    
    id annotation = view.annotation;
    
    if ([annotation isKindOfClass:[OBAStopV2 class]]) {
        OBAStopV2 * stop = annotation;
        OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationDelegate:self.appDelegate stopId:stop.stopId];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if( [annotation isKindOfClass:[OBAPlacemark class]] ) {
        OBAPlacemark * placemark = annotation;
        OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchPlacemark:placemark];
        [self.searchController searchWithTarget:target];
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id )overlay {    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView * polylineView  = [[MKPolylineView alloc] initWithPolyline:overlay];
        polylineView.fillColor = [UIColor blackColor];
        polylineView.strokeColor = [UIColor blackColor];
        polylineView.lineWidth = 5;
        return polylineView;
    }
    else {
        return nil;
    }
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1 &&  buttonIndex == 0) {
        
    } else if (alertView.tag == 2 && buttonIndex == 0) {
        OBANavigationTarget * target = [OBANavigationTarget target:OBANavigationTargetTypeAgencies];;
        [self.appDelegate navigateToTarget:target];
    } 
}

#pragma mark - IBActions

- (IBAction)onCrossHairsButton:(id)sender {
    OBALogDebug(@"setting auto center on current location");
    self.mapRegionManager.lastRegionChangeWasProgramatic = YES;
    [self refreshCurrentLocation];
}


- (IBAction)showListView:(id)sender {

    OBASearchResult * result = self.searchController.result;

    if (result) {
        // Prune down the results to show only what's currently in the map view
        result = [result resultsInRegion:self.mapView.region];
    }

    OBASearchResultsListViewController *listViewController = [[OBASearchResultsListViewController alloc]initWithContext:self.appDelegate searchControllerResult:result];
    listViewController.isModal = YES;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:listViewController];
    nav.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:nav animated:YES completion:nil];
}

@end


#pragma mark - OBASearchMapViewController Private Methods

@implementation OBASearchResultsMapViewController (Private)

- (void) refreshCurrentLocation {
    
    OBALocationManager * lm = self.appDelegate.locationManager;
    CLLocation * location = lm.currentLocation;

    if( location ) {
        OBALogDebug(@"refreshCurrentLocation: auto center on current location: %d", self.mapRegionManager.lastRegionChangeWasProgramatic);
        
        if (self.mapRegionManager.lastRegionChangeWasProgramatic) {
            double radius = MAX(location.horizontalAccuracy,kMinMapRadius);
            MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:location.coordinate latRadius:radius lonRadius:radius];
            [self.mapRegionManager setRegion:region changeWasProgramatic:YES];
        }        
    }
}

- (void) scheduleRefreshOfStopsInRegion:(NSTimeInterval)interval location:(CLLocation*)location {
    
    MKCoordinateRegion region = self.mapView.region;
    
    BOOL moreAccurateRegion = self.mostRecentLocation != nil && location != nil && location.horizontalAccuracy < self.mostRecentLocation.horizontalAccuracy;
    BOOL containedRegion = [OBASphericalGeometryLibrary isRegion:region containedBy:self.mostRecentRegion];
    
    OBALogDebug(@"scheduleRefreshOfStopsInRegion: %f %d %d", interval, moreAccurateRegion, containedRegion);
    if(!moreAccurateRegion && containedRegion) {
        NSString * label = [self computeLabelForCurrentResults];
        [self applyMapLabelWithText:label];
        return;
    }
    
    self.mostRecentLocation = location;

    if (self.refreshTimer) {
        [self.refreshTimer invalidate];
    }
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refreshStopsInRegion) userInfo:nil repeats:NO];
}
               
- (NSTimeInterval) getRefreshIntervalForLocationAccuracy:(CLLocation*)location {
    if( location == nil )
        return kStopsInRegionRefreshDelayOnDrag;
    if( location.horizontalAccuracy < 20 )
        return 0;
    if( location.horizontalAccuracy < 200 )
        return 0.25;
    if( location.horizontalAccuracy < 500 )
        return 0.5;
    if( location.horizontalAccuracy < 1000 )
        return 1;
    return 1.5;
}

- (void) refreshStopsInRegion {
    self.refreshTimer = nil;
    
    MKCoordinateRegion region = self.mapView.region;
    MKCoordinateSpan span = region.span;

    if (span.latitudeDelta > kMaxLatDeltaToShowStops) {
        // Reset the most recent region
        CLLocationCoordinate2D p = {0,0};
        self.mostRecentRegion = MKCoordinateRegionMake(p, MKCoordinateSpanMake(0,0));
        
        OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchNone];
        [self.searchController searchWithTarget:target];
    } else {
        span.latitudeDelta  *= kRegionScaleFactor;
        span.longitudeDelta *= kRegionScaleFactor;
        region.span = span;
    
        self.mostRecentRegion = region;
    
        OBANavigationTarget * target = [OBASearch getNavigationTargetForSearchLocationRegion:region];
        [self.searchController searchWithTarget:target];
    }
}

- (void) refreshSearchToolbar {
    // show the UIToolbar at the bottom of the view controller
    //
    UINavigationController * navController = self.navigationController;
    NSString * searchFilterDesc = [self computeSearchFilterString];
    if (searchFilterDesc != nil && navController.visibleViewController == self)
        [self.filterToolbar showWithDescription:searchFilterDesc animated:NO];
    else {
        [self.filterToolbar hideWithAnimated:YES];
    }

}

- (void) reloadData {
    OBASearchResult * result = self.searchController.result;
    self.navigationItem.rightBarButtonItem.enabled = result != nil;
    
    if( result && result.searchType == OBASearchTypeRoute && [result.values count] > 0) {
        [self performSelector:@selector(showListView:) withObject:self afterDelay:1];
        return;
    }
    
    if (result && result.searchType == OBASearchTypeAgenciesWithCoverage) {
        self.navigationItem.titleView = nil;
        self.navigationItem.title = NSLocalizedString(@"Agencies", @"self.navigationItem.title");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed)];
    }
    
    //[self refreshCurrentLocation];
    [self setAnnotationsFromResults];
    [self setOverlaysFromResults];
    [self setRegionFromResults];
    
    NSString * label = [self computeLabelForCurrentResults];
    [self applyMapLabelWithText:label];

    [self refreshSearchToolbar];
    [self checkResults];
}

- (void) applyMapLabelWithText:(NSString*)labelText {
    if (labelText && self.mapLabel.hidden) {
        self.mapLabel.text = labelText;
        self.mapLabel.alpha = 0.f;
        self.mapLabel.hidden = NO;
        [UIView animateWithDuration:kMapLabelAnimationDuration animations:^{
            self.mapLabel.alpha = 1.f;
        }];
    }
    else if (labelText){
        self.mapLabel.text = labelText;
    }
    else if (!labelText) {
        [UIView animateWithDuration:kMapLabelAnimationDuration animations:^{
            self.mapLabel.alpha = 0;
        } completion:^(BOOL finished) {
            self.mapLabel.hidden = YES;
        }];
    }
}

- (CLLocation*) currentLocation {
    if (self.appDelegate.locationManager.currentLocation) {
        return self.appDelegate.locationManager.currentLocation;
    }
    else if (self.searchController.searchLocation) {
        return self.searchController.searchLocation;
    }
    else {
        return [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude];
    }
}

- (void) showLocationServicesAlert {

    self.navigationItem.leftBarButtonItem.enabled = NO;
    
    if (! [self.appDelegate.modelDao hideFutureLocationWarnings]) {
        [self.appDelegate.modelDao setHideFutureLocationWarnings:YES];
        
        UIAlertView * view = [[UIAlertView alloc] init];
        view.title = NSLocalizedString(@"Location Services Disabled",@"view.title");
        view.message = NSLocalizedString(@"Location Services are disabled for this app. Some location-aware functionality will be missing.",@"view.message");
        [view addButtonWithTitle:NSLocalizedString(@"Dismiss",@"view addButtonWithTitle")];
        view.cancelButtonIndex = 0;
        [view show];
    }        
}

- (void)didCompleteNetworkRequest {
    self.hideFutureNetworkErrors = NO;
}

- (void) setAnnotationsFromResults {
    NSMutableArray * annotations = [[NSMutableArray alloc] init];
    
    OBASearchResult * result = self.searchController.result;
    
    if( result ) {
        [annotations addObjectsFromArray:result.values];

        if( result.searchType == OBASearchTypeAgenciesWithCoverage ) {           
            for( OBAAgencyWithCoverageV2 * agencyWithCoverage in result.values ) {
                OBAAgencyV2 * agency = agencyWithCoverage.agency;
                OBANavigationTargetAnnotation * an = [[OBANavigationTargetAnnotation alloc] initWithTitle:agency.name subtitle:nil coordinate:agencyWithCoverage.coordinate target:nil];
                [annotations addObject:an];
            }
        }
    }

    NSMutableArray * toAdd = [[NSMutableArray alloc] init];
    NSMutableArray * toRemove = [[NSMutableArray alloc] init];
    
    for( id annotation in [self.mapView annotations] ) {
        if( ! [annotations containsObject:annotation] && [annotation class] != MKUserLocation.class)
            [toRemove addObject:annotation];
    }
    
    for( id annotation in annotations ) {
        if( ! [[self.mapView annotations] containsObject:annotation] )
            [toAdd addObject:annotation];
    }
    
    OBALogDebug(@"Annotations to remove: %d",[toRemove count]);
    OBALogDebug(@"Annotations to add: %d", [toAdd count]);
    
    [self.mapView removeAnnotations:toRemove];
    [self.mapView addAnnotations:toAdd];
    
}

- (void) setOverlaysFromResults {
    [self.mapView removeOverlays:self.mapView.overlays];

    OBASearchResult * result = self.searchController.result;
    
    if( result && result.searchType == OBASearchTypeRouteStops) {
        for( NSString * polylineString in result.additionalValues ) {
            MKPolyline * polyline = [OBASphericalGeometryLibrary decodePolylineStringAsMKPolyline:polylineString];
            [self.mapView  addOverlay:polyline];
        }
    }
}

- (NSString*) computeSearchFilterString {

    OBASearchType type = self.searchController.searchType;
    id param = self.searchController.searchParameter;

    switch(type) {
        case OBASearchTypeRoute:
            return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Route",@"route"), param];    
        case OBASearchTypeRouteStops: {
            OBARouteV2 * route = [self.appDelegate.references getRouteForId:param];
            if( route )
                return [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Route",@"route") , [route safeShortName]];
            return NSLocalizedString(@"Route",@"route");
        }
        case OBASearchTypeStopId:
            return [NSString stringWithFormat:@"%@ # %@",NSLocalizedString(@"Stop",@"OBASearchTypeStopId") , param];    
        case OBASearchTypeAgenciesWithCoverage:
            return NSLocalizedString(@"Transit Agencies",@"OBASearchTypeAgenciesWithCoverage");
        case OBASearchTypeAddress:
            return param;
        case OBASearchTypeNone:            
        case OBASearchTypeRegion:
        case OBASearchTypePlacemark:
        case OBASearchTypePending:
        default:
            return nil;
    }
    
    return nil;
}

- (NSString*) computeLabelForCurrentResults {
    OBASearchResult * result = self.searchController.result;
    
    MKCoordinateRegion region = self.mapView.region;
    MKCoordinateSpan span = region.span;
    
    NSString * defaultLabel = nil;
    if( span.latitudeDelta > kMaxLatDeltaToShowStops )
        defaultLabel = NSLocalizedString(@"Zoom in to look for stops",@"span.latitudeDelta > kMaxLatDeltaToShowStops");
    
    if( !result )
        return defaultLabel;

    switch( result.searchType ) {
        case OBASearchTypeRoute:
        case OBASearchTypeRouteStops:    
        case OBASearchTypeAddress:
        case OBASearchTypeAgenciesWithCoverage:
        case OBASearchTypeStopId:
            return nil;
            
        case OBASearchTypePlacemark:
        case OBASearchTypeRegion: {
            if( result.limitExceeded )
                return NSLocalizedString(@"Too many stops. Zoom in for more detail",@"result.limitExceeded");
            if(![self checkStopsInRegion] && span.latitudeDelta <= kMaxLatDeltaToShowStops)
                defaultLabel = NSLocalizedString(@"No stops at this location",@"[values count] == 0");
            break;

        }

        case OBASearchTypePending:
        case OBASearchTypeNone:
            break;
    }
    if (self.appDelegate.modelDao.region && [self outOfServiceArea]) {
        return NSLocalizedString(@"Out of OneBusAway service area",@"result.outOfRange");
    }
    return defaultLabel;
}


- (void) setRegionFromResults {
    
    BOOL needsUpdate = NO;
    MKCoordinateRegion region = [self computeRegionForCurrentResults:&needsUpdate];
    if( needsUpdate ) {
        OBALogDebug(@"setRegionFromResults");
        [self.mapRegionManager setRegion:region changeWasProgramatic:NO];
    }
}


- (MKCoordinateRegion) computeRegionForCurrentResults:(BOOL*)needsUpdate {
    
    *needsUpdate = YES;
    
    OBASearchResult *result = self.searchController.result;
    
    if (!result || (result.values.count == 0 && result.additionalValues.count == 0)) {
        *needsUpdate = NO;
        return self.mapView.region;
    }
    
    switch (result.searchType) {
        case OBASearchTypeStopId:
            return [self computeRegionForNClosestStops:result.values center:[self currentLocation] numberOfStops:kShowNClosestStops];
        case OBASearchTypeRoute:
        case OBASearchTypeRouteStops:    
            return [self computeRegionForNearbyStops:result.values];
        case OBASearchTypePlacemark:
            return [self computeRegionForPlacemarks:result.additionalValues andStops:result.values];
        case OBASearchTypeAddress:
            return [self computeRegionForPlacemarks:result.values];
        case OBASearchTypeAgenciesWithCoverage:
            return [self computeRegionForAgenciesWithCoverage:result.values];
        case OBASearchTypeNone:
        case OBASearchTypeRegion:
        default:
            *needsUpdate = NO;
            return self.mapView.region;
    }
}

- (MKCoordinateRegion) computeRegionForStops:(NSArray*)stops {
    double latRun = 0.0, lonRun = 0.0;
    
    for( OBAStop * stop in stops ) {
        latRun += stop.lat;
        lonRun += stop.lon;
    }
    
    CLLocationCoordinate2D center;
    center.latitude = latRun / stops.count;
    center.longitude = lonRun / stops.count;

    CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
   
    return [self computeRegionForStops:stops center:centerLocation];
}

NSInteger sortStopsByDistanceFromLocation(id o1, id o2, void *context) {
    
    OBAStop * stop1 = (OBAStop*) o1;
    OBAStop * stop2 = (OBAStop*) o2;
    CLLocation * location = (__bridge CLLocation*)context;
    
    CLLocation * stopLocation1 = [[CLLocation alloc] initWithLatitude:stop1.lat longitude:stop1.lon];
    CLLocation * stopLocation2 = [[CLLocation alloc] initWithLatitude:stop2.lat longitude:stop2.lon];
    
    CLLocationDistance v1 = [location distanceFromLocation:stopLocation1];
    CLLocationDistance v2 = [location distanceFromLocation:stopLocation2];

    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (MKCoordinateRegion) computeRegionForNClosestStops:(NSArray*)stops center:(CLLocation*)location numberOfStops:(NSUInteger)numberOfStops {
    NSMutableArray * stopsSortedByDistance = [NSMutableArray arrayWithArray:stops];
    [stopsSortedByDistance sortUsingFunction:sortStopsByDistanceFromLocation context:(__bridge void *)(location)];
    while( [stopsSortedByDistance count] > numberOfStops )
        [stopsSortedByDistance removeLastObject];
    return [self computeRegionForStops:stopsSortedByDistance center:location];
}

- (MKCoordinateRegion) computeRegionForStops:(NSArray*)stops center:(CLLocation*)location {
    
    CLLocationCoordinate2D center = location.coordinate;
    
    MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:center latRadius:kDefaultMapRadius lonRadius:kDefaultMapRadius];
    MKCoordinateSpan span = region.span;
    
    for( OBAStop * stop in stops ) {
        double latDelta = ABS(stop.lat - center.latitude) * 2.0 * kPaddingScaleFactor;
        double lonDelta = ABS(stop.lon - center.longitude) * 2.0 * kPaddingScaleFactor;
        
        span.latitudeDelta  = MAX(span.latitudeDelta,latDelta);
        span.longitudeDelta = MAX(span.longitudeDelta,lonDelta);
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
        CLLocationDistance d = [location distanceFromLocation:center];
        if( d < kMaxMapDistanceFromCurrentLocationForNearby )
            [stopsInRange addObject:stop];
    }
    
    if( [stopsInRange count] > 0)
        return [self computeRegionForStops:stopsInRange center:center];
    else
        return [self computeRegionForStops:stops];
}

- (MKCoordinateRegion) computeRegionForPlacemarks:(NSArray*)placemarks {
    
    OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
    
    for( OBAPlacemark * placemark in placemarks )
        [bounds addCoordinate:placemark.coordinate];
    
    if( bounds.empty )
        return self.mapView.region;
    
    return bounds.region;
}

- (MKCoordinateRegion) computeRegionForPlacemarks:(NSArray*)placemarks andStops:(NSArray*)stops {
    
    CLLocation * center = [self currentLocation];
    
    for( OBAPlacemark * placemark in placemarks ) {
        CLLocationCoordinate2D coordinate = placemark.coordinate;
        center = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    }
    
    return [self computeRegionForNClosestStops:stops center:center numberOfStops:kShowNClosestStops];
}

- (MKCoordinateRegion) computeRegionForAgenciesWithCoverage:(NSArray*)agenciesWithCoverage {
    if (0 == agenciesWithCoverage.count) {
        return self.mapView.region;
    }
    
    OBACoordinateBounds * bounds = [OBACoordinateBounds bounds];
    
    for( OBAAgencyWithCoverage * agencyWithCoverage in agenciesWithCoverage )
        [bounds addCoordinate:agencyWithCoverage.coordinate];
    
    if( bounds.empty )
        return self.mapView.region;
    
    MKCoordinateRegion region = bounds.region;
    
    MKCoordinateRegion minRegion = [OBASphericalGeometryLibrary createRegionWithCenter:region.center latRadius:50000 lonRadius:50000];
    
    if( region.span.latitudeDelta < minRegion.span.latitudeDelta )
        region.span.latitudeDelta = minRegion.span.latitudeDelta;
    
    if( region.span.longitudeDelta < minRegion.span.longitudeDelta )
        region.span.longitudeDelta = minRegion.span.longitudeDelta;
    
    return region;
}

- (MKCoordinateRegion) getLocationAsRegion:(CLLocation*)location {
    double radius = MAX(location.horizontalAccuracy,kMinMapRadius);
    MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:location.coordinate latRadius:radius lonRadius:radius];    
    region = [self.mapView regionThatFits:region];
    return region;
}

- (void) checkResults {
    
    OBASearchResult * result = self.searchController.result;
    if( ! result )
        return;
    
    switch (result.searchType) {
        case OBASearchTypeRegion:
        case OBASearchTypePlacemark:
            [self checkOutOfRangeResults];
            break;
        case OBASearchTypeRoute:            
            if( ! [self checkOutOfRangeResults] )
                [self checkNoRouteResults];
            break;
        case OBASearchTypeAddress:
            if( ! [self checkOutOfRangeResults] )
                [self checkNoPlacemarksResults];
            break;
        case OBASearchTypeStopId:
            if( ! [self checkOutOfRangeResults] )
                [self checkNoStopIdResults];
            break;
        default:
            break;
    }
}

- (BOOL)checkOutOfRangeResults {
    if (self.searchController.result.outOfRange) {
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"Out of range",@"showNoResultsAlertWithTitle")
                                   prompt:NSLocalizedString(@"You are outside the OneBusAway service area.",@"prompt")];
    }

    return self.searchController.result.outOfRange;
}

- (void)checkNoRouteResults {
    if (0 == self.searchController.result.values.count) {
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"No routes found",@"showNoResultsAlertWithTitle")
                                   prompt:NSLocalizedString(@"No routes were found for your search.",@"prompt")];
    }
}

- (void)checkNoStopIdResults {
    if (0 == self.searchController.result.values.count) {
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"No stops found",@"showNoResultsAlertWithTitle")
                                   prompt:NSLocalizedString(@"No stops were found for your search.",@"prompt")];
    }
}

- (void) checkNoPlacemarksResults {
    OBASearchResult * result = self.searchController.result;
    if( [result.values count] == 0 ) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self showNoResultsAlertWithTitle: NSLocalizedString(@"No places found",@"showNoResultsAlertWithTitle") prompt:NSLocalizedString(@"No places were found for your search.",@"prompt")];
    }
}

- (void) showNoResultsAlertWithTitle:(NSString*)title prompt:(NSString*)prompt {

    self.navigationItem.rightBarButtonItem.enabled = NO;

    if (!self.controllerIsVisibleAndActive) {
        return;
    }

    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.tag = 2;
    alert.title = title;
    alert.message = [NSString stringWithFormat:@"%@ %@",prompt,NSLocalizedString(@"See the list of supported transit agencies.",@"view.message")];
    alert.delegate = self;
    [alert addButtonWithTitle:NSLocalizedString(@"Agencies",@"OBASearchTypeAgenciesWithCoverage")];
    [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", @"")];
    alert.cancelButtonIndex = 1;
    [alert show];
}

- (void) cancelPressed
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.navigationItem.titleView = self.titleView;
    } else {
        self.navigationItem.titleView = self.searchBar;   
    }
    [self.searchController searchWithTarget:[OBASearch getNavigationTargetForSearchNone]];
    [self refreshStopsInRegion];
    self.navigationItem.rightBarButtonItem = self.listBarButtonItem;
    
}

- (BOOL) controllerIsVisibleAndActive {
    if (!self.appDelegate.active) {
        // Ignore errors if our app isn't currently active
        return NO;
    }
    else if (self != self.navigationController.visibleViewController) {
        // Ignore errors if our view isn't currently on top
        return NO;
    }
    else {
        return YES;
    }
    
}    


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_searchBar.isFirstResponder)
        [self searchBarCancelButtonClicked:_searchBar];
}
-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}
-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}
- (BOOL)outOfServiceArea{
    MKMapRect viewRect = self.mapView.visibleMapRect;
    for (OBARegionBoundsV2 *bounds in self.appDelegate.modelDao.region.bounds) {
        
        
        MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                          bounds.lat+ bounds.latSpan/ 2,
                                                                          bounds.lon - bounds.lonSpan/ 2));
        MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                          bounds.lat - bounds.latSpan / 2,
                                                                          bounds.lon + bounds.lonSpan / 2));
        
        MKMapRect serviceRect = MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
        
        if (MKMapRectIntersectsRect(serviceRect, viewRect)) {
            return NO;
        }
    }
    return YES;
}

MKMapRect MKMapRectForCoordinateRegion(MKCoordinateRegion region) {
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude + region.span.latitudeDelta / 2,
                                                                      region.center.longitude - region.span.longitudeDelta / 2));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                                      region.center.latitude - region.span.latitudeDelta / 2,
                                                                      region.center.longitude + region.span.longitudeDelta / 2));
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

- (CLLocationDistance)getDistanceFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end {
    CLLocation *startLoc = [[CLLocation alloc] initWithLatitude:start.latitude longitude:start.longitude];
    CLLocation *endLoc = [[CLLocation alloc] initWithLatitude:end.latitude longitude:end.longitude];
    CLLocationDistance distance = [startLoc distanceFromLocation:endLoc];
    return distance;
}

- (CLRegion*)convertVisibleMapIntoCLRegion {
    MKMapRect mRect = self.mapView.visibleMapRect;
    MKMapPoint neMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), mRect.origin.y);
    MKMapPoint swMapPoint = MKMapPointMake(mRect.origin.x, MKMapRectGetMaxY(mRect));
    CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
    CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);
    CLLocationDistance diameter = [self getDistanceFrom:neCoord to:swCoord];
    return [[CLRegion alloc] initCircularRegionWithCenter: self.mapView.centerCoordinate radius:(diameter/2) identifier:@"mapRegion"];
}

- (BOOL)checkStopsInRegion {
    if ([[self.mapView annotationsInMapRect:self.mapView.visibleMapRect] count] > 0) {
        return YES;
    }
    NSMutableArray *annotations = [NSMutableArray arrayWithArray:[self.mapView annotations]];
    if (self.mapView.userLocation ) {
        [annotations removeObject:self.mapView.userLocation];
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        for (id <MKAnnotation> annotation in annotations) {
            MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annotation];
            MKCoordinateRegion annotationRegion = [self.mapView convertRect:annotationView.frame toRegionFromView:self.mapView];
            MKMapRect annotationRect = MKMapRectForCoordinateRegion(annotationRegion);
            
            if (MKMapRectIntersectsRect(self.mapView.visibleMapRect, annotationRect)) {
                return YES;
            }
        }
    } else {
        for (id <MKAnnotation> annotation in annotations) {
            if ([annotation isKindOfClass:[OBAStopV2 class]]) {
                OBAStopV2 *stop = (OBAStopV2*)annotation;
                CLLocationCoordinate2D annotationCoord = stop.coordinate;
                
                CGPoint annotationPoint = [self.mapView convertCoordinate:annotationCoord toPointToView:self.mapView];
                CGRect annotationFrame;
                if(stop.direction.length == 2){
                    annotationFrame = CGRectMake(annotationPoint.x-17.5, annotationPoint.y-17.5, 35, 35);
                } else if (stop.direction.length == 1){
                    if ([stop.direction isEqualToString:@"E"] || [stop.direction isEqualToString:@"W"]) {
                        annotationFrame = CGRectMake(annotationPoint.x-20.5, annotationPoint.y-15, 41, 30);
                    } else {
                        annotationFrame = CGRectMake(annotationPoint.x-15, annotationPoint.y-20.5, 30, 41);
                    }
                } else {
                    annotationFrame = CGRectMake(annotationPoint.x-15, annotationPoint.y-15, 30, 30);
                }
                
                MKCoordinateRegion annotationRegion = [self.mapView convertRect:annotationFrame toRegionFromView:self.mapView];

                MKMapRect annotationRect = MKMapRectForCoordinateRegion(annotationRegion);
                
                if (MKMapRectIntersectsRect(self.mapView.visibleMapRect, annotationRect)) {
                    return YES;
                }
            }
        }
    }
    return NO;
}
@end


