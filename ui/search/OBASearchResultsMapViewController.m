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
#import "OBAStopV2.h"
#import "OBARouteV2.h"
#import "OBAAgencyWithCoverageV2.h"
#import "OBAGenericAnnotation.h"
#import "OBANavigationTargetAnnotation.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBAProgressIndicatorView.h"
#import "OBASearchResultsListViewController.h"
#import "OBABookmarksViewController.h"
#import "OBARecentStopsViewController.h"
#import "OBAGenericStopViewController.h"
#import "OBACoordinateBounds.h"
#import "OBALogger.h"
#import "OBAStopIconFactory.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBAInfoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OBAAnalytics.h"
#import "OBAAlerts.h"

#define kScopeViewAnimationDuration 0.25
#define kRouteSegmentIndex          0
#define kAddressSegmentIndex        1
#define kStopNumberSegmentIndex     2
#define kMapLabelAnimationDuration  0.25

// Radius in meters
static const double kDefaultMapRadius = 100;
static const double kMinMapRadius = 150;
static const double kMaxLatDeltaToShowStops = 0.008;
static const double kRegionScaleFactor = 1.5;

static const double kMaxMapDistanceFromCurrentLocationForNearby = 800;
static const double kPaddingScaleFactor = 1.075;
static const NSUInteger kShowNClosestStops = 4;

static const double kStopsInRegionRefreshDelayOnDrag = 0.1;

@interface OBASearchResultsMapViewController ()
@property BOOL hideFutureOutOfRangeErrors;
@property BOOL hideFutureNetworkErrors;
@property BOOL doneLoadingMap;
@property MKCoordinateRegion mostRecentRegion;
@property (strong) CLLocation *mostRecentLocation;
@property (strong) NSTimer *refreshTimer;
@property (strong) OBAMapRegionManager *mapRegionManager;
@property (strong) OBASearchController *searchController;
@property (strong) UIView *activityIndicatorWrapper;
@property (strong) UIActivityIndicatorView *activityIndicatorView;
@property (strong) UIButton *locationButton;
@property (strong) UIBarButtonItem *listBarButtonItem;
@property (strong) OBASearchResultsListViewController *searchResultsListViewController;
@property (nonatomic) BOOL secondSearchTry;
@property (strong) OBANavigationTarget *savedNavigationTarget;
@property (nonatomic) UIView *titleView;
@end

@interface OBASearchResultsMapViewController (Private)

- (void)refreshCurrentLocation;

- (void)scheduleRefreshOfStopsInRegion:(NSTimeInterval)interval location:(CLLocation *)location;
- (NSTimeInterval)getRefreshIntervalForLocationAccuracy:(CLLocation *)location;
- (void)refreshStopsInRegion;

- (void)reloadData;
- (CLLocation *)currentLocation;

- (void)showLocationServicesAlert;

- (void)didCompleteNetworkRequest;

- (void)setAnnotationsFromResults;
- (void)setOverlaysFromResults;
- (void)setRegionFromResults;

- (NSString *)computeSearchFilterString;
- (NSString *)computeLabelForCurrentResults;
- (void)applyMapLabelWithText:(NSString *)labelText;

- (MKCoordinateRegion)computeRegionForCurrentResults:(BOOL *)needsUpdate;
- (MKCoordinateRegion)computeRegionForStops:(NSArray *)stops;
- (MKCoordinateRegion)computeRegionForNClosestStops:(NSArray *)stops center:(CLLocation *)location numberOfStops:(NSUInteger)numberOfStops;
- (MKCoordinateRegion)computeRegionForPlacemarks:(NSArray *)stops;
- (MKCoordinateRegion)computeRegionForStops:(NSArray *)stops center:(CLLocation *)location;
- (MKCoordinateRegion)computeRegionForNearbyStops:(NSArray *)stops;
- (MKCoordinateRegion)computeRegionForPlacemarks:(NSArray *)placemarks andStops:(NSArray *)stops;
- (MKCoordinateRegion)computeRegionForAgenciesWithCoverage:(NSArray *)agenciesWithCoverage;
- (MKCoordinateRegion)getLocationAsRegion:(CLLocation *)location;

- (void)checkResults;
- (BOOL)checkOutOfRangeResults;
- (void)checkNoRouteResults;
- (void)checkNoPlacemarksResults;
- (void)checkNoStopIdResults;

- (void)showNoResultsAlertWithTitle:(NSString *)title prompt:(NSString *)prompt;

- (void)cancelPressed;
- (BOOL)controllerIsVisibleAndActive;
- (BOOL)outOfServiceArea;

- (CLLocationDistance)getDistanceFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end;
- (CLCircularRegion *)convertVisibleMapIntoCLCircularRegion;

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

- (void)dealloc {
    [self.searchController cancelOpenConnections];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect indicatorBounds = CGRectMake(12, 12, 36, 36);
    indicatorBounds.origin.y += self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;

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

    CLLocationCoordinate2D p = { 0, 0 };
    self.mostRecentRegion = MKCoordinateRegionMake(p, MKCoordinateSpanMake(0, 0));

    self.refreshTimer = nil;

    self.mapRegionManager = [[OBAMapRegionManager alloc] initWithMapView:self.mapView];
    self.mapRegionManager.lastRegionChangeWasProgrammatic = YES;
    
    self.mapView.rotateEnabled = NO;

    self.hideFutureNetworkErrors = NO;

    self.searchController = [[OBASearchController alloc] init];
    self.searchController.delegate = self;
    self.searchController.progress.delegate = self;

    if (self.savedNavigationTarget) {
        [self.searchController searchWithTarget:self.savedNavigationTarget];
        self.savedNavigationTarget = nil;
    }

    self.navigationItem.leftBarButtonItem = [self getArrowButton];

    self.listBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"lines"] style:UIBarButtonItemStylePlain target:self action:@selector(showListView:)];
    self.listBarButtonItem.accessibilityLabel = NSLocalizedString(@"Nearby stops list", @"self.listBarButtonItem.accessibilityLabel");
    self.navigationItem.rightBarButtonItem = self.listBarButtonItem;

    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    [self.titleView addSubview:self.searchBar];
    self.navigationItem.titleView = self.titleView;

    if ([[OBAApplication sharedApplication] useHighContrastUI]) {
        [self setHighContrastStyle];
    }
    else {
        [self setRegularStyle];
    }

    self.mapLabel.hidden = YES;
    self.mapLabel.alpha = 0;

    CALayer *labelLayer = self.mapLabel.layer;
    labelLayer.rasterizationScale = [UIScreen mainScreen].scale;
    labelLayer.shouldRasterize = YES;
    labelLayer.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.9f].CGColor;
    labelLayer.cornerRadius = 7;

    labelLayer.shadowColor = [UIColor blackColor].CGColor;
    labelLayer.shadowOpacity = 0.2f;
    labelLayer.shadowOffset = CGSizeMake(0, 0);
    labelLayer.shadowRadius = 7;

    [self orientationChanged:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMapTabBarButton) name:@"OBAMapButtonRecenterNotification" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self refreshCurrentLocation];
}

- (void)orientationChanged:(NSNotification*)notification{
    [self updateMapLabelFrame];
}

- (void)updateMapLabelFrame
{
    CGRect mapLabelFrame = self.mapLabel.frame;
    mapLabelFrame.origin.y = 8 + self.navigationController.navigationBar.frame.size.height +
    [UIApplication sharedApplication].statusBarFrame.size.height;
    self.mapLabel.frame = mapLabelFrame;
}

- (void)setHighContrastStyle {
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAccessibility action:@"increase_contrast" label:[NSString stringWithFormat:@"Loaded view: %@ with Increased Contrast", [self class]] value:nil];

    self.searchBar.barTintColor = OBADARKGREEN;
    self.searchBar.tintColor = [UIColor whiteColor];

    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.tabBarController.tabBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];

    self.scopeView.backgroundColor = [UIColor blackColor];
    self.scopeView.tintColor = OBADARKGREEN;
}

- (void)setRegularStyle {
    self.searchBar.barTintColor = nil;
    self.searchBar.tintColor = nil;

    self.navigationController.navigationBar.barTintColor = nil;
    self.navigationController.tabBarController.tabBar.barTintColor = nil;
    self.navigationController.navigationBar.tintColor = OBAGREEN;

    self.scopeView.backgroundColor = OBAGREENWITHALPHA(0.8f);
    self.scopeView.tintColor = nil;
}

- (void)onFilterClear {
    [self refreshStopsInRegion];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    OBALocationManager *lm = [OBAApplication sharedApplication].locationManager;
    [lm addDelegate:self];
    [lm startUpdatingLocation];

    if (self.searchController.unfilteredSearch) {
        [self refreshStopsInRegion];
    }
    
    if ([OBAApplication sharedApplication].modelDao.region.regionName) {
        self.searchBar.placeholder = [NSString stringWithFormat:NSLocalizedString(@"Search %@",@"Search {Region Name}"), [OBAApplication sharedApplication].modelDao.region.regionName];
    }
    else {
        self.searchBar.placeholder = NSLocalizedString(@"Search", @"");
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[OBAApplication sharedApplication].locationManager stopUpdatingLocation];
    [[OBAApplication sharedApplication].locationManager removeDelegate:self];
}

- (UIBarButtonItem *)getArrowButton {
    UIBarButtonItem *arrowButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"lbs_arrow"] style:UIBarButtonItemStylePlain target:self action:@selector(onCrossHairsButton:)];

    arrowButton.accessibilityLabel = NSLocalizedString(@"my location", @"arrowButton.accessibilityLabel");
    arrowButton.accessibilityHint = NSLocalizedString(@"centers the map on current location", @"arrowButton.accessibilityHint");
    return arrowButton;
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Search box selected" value:nil];

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
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Cancel search button clicked" value:nil];

    [searchBar endEditing:YES];
    [self cancelPressed];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Search button clicked" value:nil];

    OBANavigationTarget *target = nil;
    self.searchController.searchRegion = [self convertVisibleMapIntoCLCircularRegion];

    if (kRouteSegmentIndex == self.searchTypeSegmentedControl.selectedSegmentIndex) {
        target = [OBASearch getNavigationTargetForSearchRoute:searchBar.text];
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Search: Route" value:nil];
    }
    else if (kAddressSegmentIndex == self.searchTypeSegmentedControl.selectedSegmentIndex) {
        target = [OBASearch getNavigationTargetForSearchAddress:searchBar.text];
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Search: Address" value:nil];
    }
    else {
        target = [OBASearch getNavigationTargetForSearchStopCode:searchBar.text];
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Search: Stop" value:nil];
    }

    [APP_DELEGATE navigateToTarget:target];
    [searchBar endEditing:YES];
}

- (void)animateInScopeView {
    CGRect offscreenScopeFrame = self.scopeView.frame;

    offscreenScopeFrame.size.width = CGRectGetWidth(self.view.frame);
    offscreenScopeFrame.origin.y = -offscreenScopeFrame.size.height;
    self.scopeView.frame = offscreenScopeFrame;
    [self.view addSubview:self.scopeView];

    CGRect finalScopeFrame = self.scopeView.frame;

    finalScopeFrame.origin.y = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;

    [UIView animateWithDuration:kScopeViewAnimationDuration
                     animations:^{
                         self.scopeView.frame = finalScopeFrame;
                     }];
}

- (void)animateOutScopeView {
    CGRect offscreenScopeFrame = self.scopeView.frame;

    offscreenScopeFrame.origin.y = -offscreenScopeFrame.size.height;

    [UIView animateWithDuration:kScopeViewAnimationDuration
                     animations:^{
                         self.scopeView.frame = offscreenScopeFrame;
                     }

                     completion:^(BOOL finished) {
                         [self.scopeView removeFromSuperview];
                     }];
}

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    if (OBASearchTypeRegion == self.searchController.searchType) {
        return [OBASearch getNavigationTargetForSearchLocationRegion:self.mapView.region];
    }
    else {
        return [self.searchController getSearchTarget];
    }
}

- (void)setNavigationTarget:(OBANavigationTarget *)target {
    OBASearchType searchType = [OBASearch getSearchTypeForNagivationTarget:target];

    if (OBASearchTypeRegion == searchType) {
        [self.searchController searchPending];

        NSDictionary *parameters = target.parameters;
        NSData *data = parameters[kOBASearchControllerSearchArgumentParameter];
        MKCoordinateRegion region;
        [data getBytes:&region length:sizeof(MKCoordinateRegion)];
        [self.mapRegionManager setRegion:region changeWasProgrammatic:NO];
    }
    else {
        if (self.searchController) {
            [self.searchController searchWithTarget:target];
        }
        else {
            self.savedNavigationTarget = target;
        }
    }
}

#pragma mark - OBASearchControllerDelegate Methods

- (void)handleSearchControllerStarted:(OBASearchType)searchType {
    if (OBASearchTypeNone != searchType && OBASearchTypeRegion != searchType) {
        self.mapRegionManager.lastRegionChangeWasProgrammatic = NO;
    }
}

- (void)handleSearchControllerUpdate:(OBASearchResult *)result {
    self.secondSearchTry = NO;
    [self reloadData];
}

- (void)handleSearchControllerError:(NSError *)error {
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

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error connecting", @"self.navigationItem.title") message:NSLocalizedString(@"There was a problem with your Internet connection.\r\n\r\nPlease check your network connection or contact us if you think the problem is on our end.", @"view.message") preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Contact Us", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [APP_DELEGATE navigateToTarget:[OBANavigationTarget target:OBANavigationTargetTypeContactUs]];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - OBALocationManagerDelegate Methods

- (void)locationManager:(OBALocationManager *)manager didUpdateLocation:(CLLocation *)location {
    [self refreshCurrentLocation];
}

- (void)locationManager:(OBALocationManager *)manager didFailWithError:(NSError *)error {
    if (kCLErrorDomain == error.domain && kCLErrorDenied == error.code) {
        [self showLocationServicesAlert];
    }
}

- (void)locationManager:(OBALocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status != kCLAuthorizationStatusNotDetermined && status != kCLAuthorizationStatusRestricted && status != kCLAuthorizationStatusDenied) {
        self.mapView.showsUserLocation = YES;
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

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    self.doneLoadingMap = true;
}

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
        if (self.mapRegionManager.lastRegionChangeWasProgrammatic) {
            OBALocationManager *lm = [OBAApplication sharedApplication].locationManager;
            double refreshInterval = [self getRefreshIntervalForLocationAccuracy:lm.currentLocation];
            [self scheduleRefreshOfStopsInRegion:refreshInterval location:lm.currentLocation];
        }
        else {
            [self scheduleRefreshOfStopsInRegion:kStopsInRegionRefreshDelayOnDrag location:nil];
        }
    }

    CGFloat scale = 1.0;
    CGFloat alpha = 1.0;

    OBASearchResult *result = self.searchController.result;

    if (result && OBASearchTypeRouteStops == result.searchType) {
        scale = [OBASphericalGeometryLibrary computeStopsForRouteAnnotationScaleFactor:mapView.region];
        alpha = scale <= 0.11f ? 0.f : 1.f;
    }

    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);

    for (id<MKAnnotation> annotation in mapView.annotations) {
        if ([annotation isKindOfClass:[OBAStopV2 class]]) {
            MKAnnotationView *view = [mapView viewForAnnotation:annotation];
            view.transform = transform;
            view.alpha = alpha;
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[OBAStopV2 class]]) {
        OBAStopV2 *stop = (OBAStopV2 *)annotation;
        static NSString *viewId = @"StopView";

        MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

        if (!view) {
            view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
        }

        view.canShowCallout = YES;
        UIButton *rightCalloutButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];

        if ([[OBAApplication sharedApplication] useHighContrastUI]) {
            rightCalloutButton.tintColor = [UIColor blackColor];
        }
        else {
            rightCalloutButton.tintColor = OBAGREEN;
        }

        view.rightCalloutAccessoryView = rightCalloutButton;

        OBASearchResult *result = self.searchController.result;

        if (result && OBASearchTypeRouteStops == result.searchType) {
            CGFloat scale = [OBASphericalGeometryLibrary computeStopsForRouteAnnotationScaleFactor:mapView.region];
            CGFloat alpha = scale <= 0.11f ? 0.f : 1.f;

            view.transform = CGAffineTransformMakeScale(scale, scale);
            view.alpha = alpha;
        }

        view.image = [OBAStopIconFactory getIconForStop:stop];
        return view;
    }
    else if ([annotation isKindOfClass:[OBAPlacemark class]]) {
        static NSString *viewId = @"NavigationTargetView";
        MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

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
        static NSString *viewId = @"NavigationTargetView";
        MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

        if (!view) {
            view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
        }

        OBANavigationTargetAnnotation *nav = annotation;

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
        OBAGenericAnnotation *ga = annotation;

        if ([@"currentLocation" isEqual:ga.context]) {
            static NSString *viewId = @"CurrentLocationView";

            MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

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
        OBAStopV2 *stop = annotation;
        OBAGenericStopViewController *vc = [[OBAGenericStopViewController alloc] initWithStopId:stop.stopId];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([annotation isKindOfClass:[OBAPlacemark class]]) {
        OBAPlacemark *placemark = annotation;
        OBANavigationTarget *target = [OBASearch getNavigationTargetForSearchPlacemark:placemark];
        [self.searchController searchWithTarget:target];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.fillColor = [UIColor blackColor];
        renderer.strokeColor = [UIColor blackColor];
        renderer.lineWidth = 5;
        return renderer;
    }
    else {
        return nil;
    }
}

#pragma mark - IBActions

- (IBAction)onCrossHairsButton:(id)sender {

    OBALocationManager *lm = [OBAApplication sharedApplication].locationManager;

    if (lm.locationServicesEnabled) {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked My Location Button" value:nil];
        OBALogDebug(@"setting auto center on current location");
        self.mapRegionManager.lastRegionChangeWasProgrammatic = YES;
        [self refreshCurrentLocation];
    }
    else {
        UIAlertController *alert = [OBAAlerts locationServicesDisabledAlert];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)onMapTabBarButton {
    if (self.isViewLoaded && self.view.window) {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"My Location via Map Tab Button" value:nil];
        OBALogDebug(@"setting auto center on current location (via tab bar)");
        self.mapRegionManager.lastRegionChangeWasProgrammatic = YES;
        [self refreshCurrentLocation];
    }
}

- (IBAction)showListView:(id)sender {
    OBASearchResult *result = self.searchController.result;

    if (result) {
        // Prune down the results to show only what's currently in the map view
        result = [result resultsInRegion:self.mapView.region];
    }

    OBASearchResultsListViewController *listViewController = [[OBASearchResultsListViewController alloc] initWithSearchControllerResult:result];
    listViewController.isModal = YES;

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:listViewController];
    nav.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:nav animated:YES completion:nil];
}

@end


#pragma mark - OBASearchMapViewController Private Methods

@implementation OBASearchResultsMapViewController (Private)

- (void)refreshCurrentLocation {
    OBALocationManager *lm = [OBAApplication sharedApplication].locationManager;
    CLLocation *location = lm.currentLocation;

    if (location) {
        //OBALogDebug(@"refreshCurrentLocation: auto center on current location: %d", self.mapRegionManager.lastRegionChangeWasprogrammatic);

        if (self.mapRegionManager.lastRegionChangeWasProgrammatic) {
            double radius = MAX(location.horizontalAccuracy, kMinMapRadius);
            MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:location.coordinate latRadius:radius lonRadius:radius];
            [self.mapRegionManager setRegion:region changeWasProgrammatic:YES];
        }
    }
}

- (void)scheduleRefreshOfStopsInRegion:(NSTimeInterval)interval location:(CLLocation *)location {
    MKCoordinateRegion region = self.mapView.region;

    BOOL moreAccurateRegion = self.mostRecentLocation != nil && location != nil && location.horizontalAccuracy < self.mostRecentLocation.horizontalAccuracy;
    BOOL containedRegion = [OBASphericalGeometryLibrary isRegion:region containedBy:self.mostRecentRegion];

    OBALogDebug(@"scheduleRefreshOfStopsInRegion: %f %d %d", interval, moreAccurateRegion, containedRegion);

    if (!moreAccurateRegion && containedRegion) {
        NSString *label = [self computeLabelForCurrentResults];
        [self applyMapLabelWithText:label];
        return;
    }

    self.mostRecentLocation = location;

    if (self.refreshTimer) {
        [self.refreshTimer invalidate];
    }

    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refreshStopsInRegion) userInfo:nil repeats:NO];
}

- (NSTimeInterval)getRefreshIntervalForLocationAccuracy:(CLLocation *)location {
    if (location == nil) return kStopsInRegionRefreshDelayOnDrag;

    if (location.horizontalAccuracy < 20) return 0;

    if (location.horizontalAccuracy < 200) return 0.25;

    if (location.horizontalAccuracy < 500) return 0.5;

    if (location.horizontalAccuracy < 1000) return 1;

    return 1.5;
}

- (void)refreshStopsInRegion {
    self.refreshTimer = nil;

    MKCoordinateRegion region = self.mapView.region;
    MKCoordinateSpan span = region.span;

    if (span.latitudeDelta > kMaxLatDeltaToShowStops) {
        // Reset the most recent region
        CLLocationCoordinate2D p = { 0, 0 };
        self.mostRecentRegion = MKCoordinateRegionMake(p, MKCoordinateSpanMake(0, 0));

        OBANavigationTarget *target = [OBASearch getNavigationTargetForSearchNone];
        [self.searchController searchWithTarget:target];
    }
    else {
        span.latitudeDelta  *= kRegionScaleFactor;
        span.longitudeDelta *= kRegionScaleFactor;
        region.span = span;

        self.mostRecentRegion = region;

        OBANavigationTarget *target = [OBASearch getNavigationTargetForSearchLocationRegion:region];
        [self.searchController searchWithTarget:target];
    }
}

- (void)reloadData {
    OBASearchResult *result = self.searchController.result;

    self.navigationItem.rightBarButtonItem.enabled = result != nil;

    if (result && result.searchType == OBASearchTypeRoute && [result.values count] > 0) {
        [self performSelector:@selector(showListView:) withObject:self afterDelay:1];
        return;
    }

    if (result && result.searchType == OBASearchTypeAgenciesWithCoverage) {
        self.navigationItem.titleView = nil;
        self.navigationItem.title = NSLocalizedString(@"Agencies", @"self.navigationItem.title");
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed)];
    }

    [self setAnnotationsFromResults];
    [self setOverlaysFromResults];
    [self setRegionFromResults];

    NSString *label = [self computeLabelForCurrentResults];
    [self applyMapLabelWithText:label];

    [self checkResults];

    if (self.doneLoadingMap && [OBAApplication sharedApplication].modelDao.region && [self outOfServiceArea]) {
        [self showOutOfRangeAlert];
    }
}

- (void)applyMapLabelWithText:(NSString *)labelText {
    if (labelText && self.mapLabel.hidden) {
        self.mapLabel.text = labelText;
        self.mapLabel.alpha = 0.f;
        self.mapLabel.hidden = NO;
        [UIView animateWithDuration:kMapLabelAnimationDuration
                         animations:^{
                             self.mapLabel.alpha = 1.f;
                         }];
    }
    else if (labelText) {
        self.mapLabel.text = labelText;
    }
    else if (!labelText) {
        [UIView animateWithDuration:kMapLabelAnimationDuration
                         animations:^{
                             self.mapLabel.alpha = 0;
                         }

                         completion:^(BOOL finished) {
                             self.mapLabel.hidden = YES;
                         }];
    }
}

- (CLLocation *)currentLocation {
    if ([OBAApplication sharedApplication].locationManager.currentLocation) {
        return [OBAApplication sharedApplication].locationManager.currentLocation;
    }
    else if (self.searchController.searchLocation) {
        return self.searchController.searchLocation;
    }
    else {
        return [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude];
    }
}

- (void)showOutOfRangeAlert {
    if (self.hideFutureOutOfRangeErrors) {
        return;
    }

    NSString *regionName = [OBAApplication sharedApplication].modelDao.region.regionName;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Go to %@?", @"Out of range alert title"), regionName]
                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"You are out of the %@ service area. Go there now?", @"Out of range alert message"), regionName]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"Out of range alert Cancel button") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.hideFutureOutOfRangeErrors = YES;
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Out of Region Alert: NO" value:nil];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Out of range alert OK button") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Out of Region Alert: YES" value:nil];
        MKMapRect serviceRect = [[OBAApplication sharedApplication].modelDao.region serviceRect];
        [self.mapRegionManager setRegion:MKCoordinateRegionForMapRect(serviceRect)];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showLocationServicesAlert {

    if (![[OBAApplication sharedApplication].modelDao hideFutureLocationWarnings]) {
        [[OBAApplication sharedApplication].modelDao setHideFutureLocationWarnings:YES];

        UIAlertController *alert = [OBAAlerts locationServicesDisabledAlert];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)didCompleteNetworkRequest {
    self.hideFutureNetworkErrors = NO;
}

- (void)setAnnotationsFromResults {
    NSMutableArray *annotations = [[NSMutableArray alloc] init];

    OBASearchResult *result = self.searchController.result;

    if (result) {
        [annotations addObjectsFromArray:result.values];

        if (result.searchType == OBASearchTypeAgenciesWithCoverage) {
            for (OBAAgencyWithCoverageV2 *agencyWithCoverage in result.values) {
                OBAAgencyV2 *agency = agencyWithCoverage.agency;
                OBANavigationTargetAnnotation *an = [[OBANavigationTargetAnnotation alloc] initWithTitle:agency.name subtitle:nil coordinate:agencyWithCoverage.coordinate target:nil];
                [annotations addObject:an];
            }
        }
    }

    NSMutableArray *toAdd = [[NSMutableArray alloc] init];
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];

    for (id annotation in [self.mapView annotations]) {
        if (![annotations containsObject:annotation] && [annotation class] != MKUserLocation.class) [toRemove addObject:annotation];
    }

    for (id annotation in annotations) {
        if (![[self.mapView annotations] containsObject:annotation]) [toAdd addObject:annotation];
    }

    OBALogDebug(@"Annotations to remove: %lu", (unsigned long)[toRemove count]);
    OBALogDebug(@"Annotations to add: %lu", (unsigned long)[toAdd count]);

    [self.mapView removeAnnotations:toRemove];
    [self.mapView addAnnotations:toAdd];
}

- (void)setOverlaysFromResults {
    [self.mapView removeOverlays:self.mapView.overlays];

    OBASearchResult *result = self.searchController.result;

    if (result && result.searchType == OBASearchTypeRouteStops) {
        for (NSString *polylineString in result.additionalValues) {
            MKPolyline *polyline = [OBASphericalGeometryLibrary decodePolylineStringAsMKPolyline:polylineString];
            [self.mapView addOverlay:polyline];
        }
    }
}

- (NSString *)computeSearchFilterString {
    OBASearchType type = self.searchController.searchType;
    id param = self.searchController.searchParameter;

    switch (type) {
        case OBASearchTypeRoute:
            return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Route", @"route"), param];

        case OBASearchTypeRouteStops: {
            OBARouteV2 *route = [[OBAApplication sharedApplication].references getRouteForId:param];

            if (route) return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Route", @"route"), [route safeShortName]];

            return NSLocalizedString(@"Route", @"route");
        }

        case OBASearchTypeStopId:
            return [NSString stringWithFormat:@"%@ # %@", NSLocalizedString(@"Stop", @"OBASearchTypeStopId"), param];

        case OBASearchTypeAgenciesWithCoverage:
            return NSLocalizedString(@"Transit Agencies", @"OBASearchTypeAgenciesWithCoverage");

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

- (NSString *)computeLabelForCurrentResults {
    OBASearchResult *result = self.searchController.result;

    MKCoordinateRegion region = self.mapView.region;
    MKCoordinateSpan span = region.span;

    NSString *defaultLabel = nil;

    if (span.latitudeDelta > kMaxLatDeltaToShowStops) defaultLabel = NSLocalizedString(@"Zoom in to look for stops", @"span.latitudeDelta > kMaxLatDeltaToShowStops");

    if (!result) return defaultLabel;

    switch (result.searchType) {
        case OBASearchTypeRoute:
        case OBASearchTypeRouteStops:
        case OBASearchTypeAddress:
        case OBASearchTypeAgenciesWithCoverage:
        case OBASearchTypeStopId:
            return nil;

        case OBASearchTypePlacemark:
        case OBASearchTypeRegion: {
            if (result.limitExceeded) return NSLocalizedString(@"Too many stops. Zoom in for more detail", @"result.limitExceeded");

            if (![self checkStopsInRegion] && span.latitudeDelta <= kMaxLatDeltaToShowStops) defaultLabel = NSLocalizedString(@"No stops at this location", @"[values count] == 0");

            break;
        }

        case OBASearchTypePending:
        case OBASearchTypeNone:
            break;
    }

    if ([OBAApplication sharedApplication].modelDao.region && [self outOfServiceArea]) {
        return NSLocalizedString(@"Out of OneBusAway service area", @"result.outOfRange");
    }

    return defaultLabel;
}

- (void)setRegionFromResults {
    BOOL needsUpdate = NO;
    MKCoordinateRegion region = [self computeRegionForCurrentResults:&needsUpdate];

    if (needsUpdate) {
        OBALogDebug(@"setRegionFromResults");
        [self.mapRegionManager setRegion:region changeWasProgrammatic:NO];
    }
}

- (MKCoordinateRegion)computeRegionForCurrentResults:(BOOL *)needsUpdate {
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

- (MKCoordinateRegion)computeRegionForStops:(NSArray *)stops {
    double latRun = 0.0, lonRun = 0.0;

    for (OBAStopV2 *stop in stops) {
        latRun += stop.lat;
        lonRun += stop.lon;
    }

    CLLocationCoordinate2D center;
    center.latitude = latRun / stops.count;
    center.longitude = lonRun / stops.count;

    CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];

    return [self computeRegionForStops:stops center:centerLocation];
}

NSInteger sortStopsByDistanceFromLocation(OBAStopV2 *stop1, OBAStopV2 *stop2, void *context) {
    CLLocation *location = (__bridge CLLocation *)context;

    CLLocation *stopLocation1 = [[CLLocation alloc] initWithLatitude:stop1.lat longitude:stop1.lon];
    CLLocation *stopLocation2 = [[CLLocation alloc] initWithLatitude:stop2.lat longitude:stop2.lon];

    CLLocationDistance v1 = [location distanceFromLocation:stopLocation1];
    CLLocationDistance v2 = [location distanceFromLocation:stopLocation2];

    if (v1 < v2) return NSOrderedAscending;
    else if (v1 > v2) return NSOrderedDescending;
    else return NSOrderedSame;
}

- (MKCoordinateRegion)computeRegionForNClosestStops:(NSArray *)stops center:(CLLocation *)location numberOfStops:(NSUInteger)numberOfStops {
    NSMutableArray *stopsSortedByDistance = [NSMutableArray arrayWithArray:stops];

    [stopsSortedByDistance sortUsingFunction:sortStopsByDistanceFromLocation context:(__bridge void *)(location)];

    while ([stopsSortedByDistance count] > numberOfStops)
        [stopsSortedByDistance removeLastObject];
    return [self computeRegionForStops:stopsSortedByDistance center:location];
}

- (MKCoordinateRegion)computeRegionForStops:(NSArray *)stops center:(CLLocation *)location {
    CLLocationCoordinate2D center = location.coordinate;

    MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:center latRadius:kDefaultMapRadius lonRadius:kDefaultMapRadius];
    MKCoordinateSpan span = region.span;

    for (OBAStopV2 *stop in stops) {
        double latDelta = ABS(stop.lat - center.latitude) * 2.0 * kPaddingScaleFactor;
        double lonDelta = ABS(stop.lon - center.longitude) * 2.0 * kPaddingScaleFactor;

        span.latitudeDelta  = MAX(span.latitudeDelta, latDelta);
        span.longitudeDelta = MAX(span.longitudeDelta, lonDelta);
    }

    region.center = center;
    region.span = span;

    return region;
}

- (MKCoordinateRegion)computeRegionForNearbyStops:(NSArray *)stops {
    NSMutableArray *stopsInRange = [NSMutableArray array];
    CLLocation *center = [self currentLocation];

    for (OBAStopV2 *stop in stops) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:stop.lat longitude:stop.lon];
        CLLocationDistance d = [location distanceFromLocation:center];

        if (d < kMaxMapDistanceFromCurrentLocationForNearby) [stopsInRange addObject:stop];
    }

    if ([stopsInRange count] > 0) return [self computeRegionForStops:stopsInRange center:center];
    else return [self computeRegionForStops:stops];
}

- (MKCoordinateRegion)computeRegionForPlacemarks:(NSArray *)placemarks {
    OBACoordinateBounds *bounds = [OBACoordinateBounds bounds];

    for (OBAPlacemark *placemark in placemarks) {
        [bounds addCoordinate:placemark.coordinate];
    }

    if (bounds.empty) return self.mapView.region;

    return bounds.region;
}

- (MKCoordinateRegion)computeRegionForPlacemarks:(NSArray *)placemarks andStops:(NSArray *)stops {
    CLLocation *center = [self currentLocation];

    for (OBAPlacemark *placemark in placemarks) {
        CLLocationCoordinate2D coordinate = placemark.coordinate;
        center = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    }

    return [self computeRegionForNClosestStops:stops center:center numberOfStops:kShowNClosestStops];
}

- (MKCoordinateRegion)computeRegionForAgenciesWithCoverage:(NSArray *)agenciesWithCoverage {
    if (0 == agenciesWithCoverage.count) {
        return self.mapView.region;
    }

    OBACoordinateBounds *bounds = [OBACoordinateBounds bounds];

    for (OBAAgencyWithCoverageV2 *agencyWithCoverage in agenciesWithCoverage) {
        [bounds addCoordinate:agencyWithCoverage.coordinate];
    }

    if (bounds.empty) return self.mapView.region;

    MKCoordinateRegion region = bounds.region;

    MKCoordinateRegion minRegion = [OBASphericalGeometryLibrary createRegionWithCenter:region.center latRadius:50000 lonRadius:50000];

    if (region.span.latitudeDelta < minRegion.span.latitudeDelta) region.span.latitudeDelta = minRegion.span.latitudeDelta;

    if (region.span.longitudeDelta < minRegion.span.longitudeDelta) region.span.longitudeDelta = minRegion.span.longitudeDelta;

    return region;
}

- (MKCoordinateRegion)getLocationAsRegion:(CLLocation *)location {
    double radius = MAX(location.horizontalAccuracy, kMinMapRadius);
    MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:location.coordinate latRadius:radius lonRadius:radius];

    region = [self.mapView regionThatFits:region];
    return region;
}

- (void)checkResults {
    OBASearchResult *result = self.searchController.result;

    if (!result) return;

    switch (result.searchType) {
        case OBASearchTypeRegion:
        case OBASearchTypePlacemark:
            [self checkOutOfRangeResults];
            break;

        case OBASearchTypeRoute:

            if (![self checkOutOfRangeResults]) [self checkNoRouteResults];

            break;

        case OBASearchTypeAddress:

            if (![self checkOutOfRangeResults]) [self checkNoPlacemarksResults];

            break;

        case OBASearchTypeStopId:

            if (![self checkOutOfRangeResults]) [self checkNoStopIdResults];

            break;

        default:
            break;
    }
}

- (BOOL)checkOutOfRangeResults {
    if (self.searchController.result.outOfRange) {
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"Out of range", @"showNoResultsAlertWithTitle")
                                   prompt:NSLocalizedString(@"You are outside the OneBusAway service area.", @"prompt")];
    }

    return self.searchController.result.outOfRange;
}

- (void)checkNoRouteResults {
    if (0 == self.searchController.result.values.count) {
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"No routes found", @"showNoResultsAlertWithTitle")
                                   prompt:NSLocalizedString(@"No routes were found for your search.", @"prompt")];
    }
}

- (void)checkNoStopIdResults {
    if (0 == self.searchController.result.values.count) {
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"No stops found", @"showNoResultsAlertWithTitle")
                                   prompt:NSLocalizedString(@"No stops were found for your search.", @"prompt")];
    }
}

- (void)checkNoPlacemarksResults {
    OBASearchResult *result = self.searchController.result;

    if ([result.values count] == 0) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"No places found", @"showNoResultsAlertWithTitle") prompt:NSLocalizedString(@"No places were found for your search.", @"prompt")];
    }
}

- (void)showNoResultsAlertWithTitle:(NSString *)title prompt:(NSString *)prompt {
    self.navigationItem.rightBarButtonItem.enabled = NO;

    if (!self.controllerIsVisibleAndActive) {
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:[NSString stringWithFormat:@"%@ %@", prompt, NSLocalizedString(@"See the list of supported transit agencies.", @"view.message")]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Agencies", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        OBANavigationTarget *target = [OBANavigationTarget target:OBANavigationTargetTypeAgencies];
        [APP_DELEGATE navigateToTarget:target];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)cancelPressed {
    self.navigationItem.titleView = self.titleView;

    [self.searchController searchWithTarget:[OBASearch getNavigationTargetForSearchNone]];
    [self refreshStopsInRegion];
    self.navigationItem.rightBarButtonItem = self.listBarButtonItem;
}

- (BOOL)controllerIsVisibleAndActive {
    if (!APP_DELEGATE.active) {
        // Ignore errors if our app isn't currently active
        return NO;
    }
    else {
        // Ignore errors if our view isn't currently on top
        return self == self.navigationController.visibleViewController;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_searchBar.isFirstResponder) [self searchBarCancelButtonClicked:_searchBar];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (BOOL)outOfServiceArea {
    MKMapRect viewRect = self.mapView.visibleMapRect;

    for (OBARegionBoundsV2 *bounds in [OBAApplication sharedApplication].modelDao.region.bounds) {
        MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                   bounds.lat + bounds.latSpan / 2,
                                                   bounds.lon - bounds.lonSpan / 2));
        MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(
                                                   bounds.lat - bounds.latSpan / 2,
                                                   bounds.lon + bounds.lonSpan / 2));

        MKMapRect serviceRect = MKMapRectMake(MIN(a.x, b.x), MIN(a.y, b.y), ABS(a.x - b.x), ABS(a.y - b.y));

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

    return MKMapRectMake(MIN(a.x, b.x), MIN(a.y, b.y), ABS(a.x - b.x), ABS(a.y - b.y));
}

- (CLLocationDistance)getDistanceFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end {
    CLLocation *startLoc = [[CLLocation alloc] initWithLatitude:start.latitude longitude:start.longitude];
    CLLocation *endLoc = [[CLLocation alloc] initWithLatitude:end.latitude longitude:end.longitude];
    CLLocationDistance distance = [startLoc distanceFromLocation:endLoc];

    return distance;
}

- (CLCircularRegion *)convertVisibleMapIntoCLCircularRegion {
    MKMapRect mRect = self.mapView.visibleMapRect;
    MKMapPoint neMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), mRect.origin.y);
    MKMapPoint swMapPoint = MKMapPointMake(mRect.origin.x, MKMapRectGetMaxY(mRect));
    CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
    CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);
    CLLocationDistance diameter = [self getDistanceFrom:neCoord to:swCoord];

    return [[CLCircularRegion alloc] initWithCenter:self.mapView.centerCoordinate radius:(diameter / 2.0) identifier:@"mapRegion"];
}

- (BOOL)checkStopsInRegion {
    if ([[self.mapView annotationsInMapRect:self.mapView.visibleMapRect] count] > 0) {
        return YES;
    }

    NSMutableArray *annotations = [NSMutableArray arrayWithArray:[self.mapView annotations]];

    if (self.mapView.userLocation) {
        [annotations removeObject:self.mapView.userLocation];
    }

    for (id <MKAnnotation> annotation in annotations) {
        MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annotation];
        MKCoordinateRegion annotationRegion = [self.mapView convertRect:annotationView.frame toRegionFromView:self.mapView];
        MKMapRect annotationRect = MKMapRectForCoordinateRegion(annotationRegion);

        if (MKMapRectIntersectsRect(self.mapView.visibleMapRect, annotationRect)) {
            return YES;
        }
    }

    return NO;
}

@end
