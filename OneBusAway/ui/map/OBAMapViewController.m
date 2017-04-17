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

#import "OBAMapViewController.h"
@import OBAKit;
@import Masonry;
@import SVProgressHUD;
#import "OBAStopViewController.h"
#import "OBAAnalytics.h"
#import "OBAAlerts.h"
#import "OBAAnimation.h"
#import "OBAMapActivityIndicatorView.h"
#import "OBAVibrantBlurContainerView.h"
#import "OneBusAway-Swift.h"
#import "SVPulsingAnnotationView.h"
#import "UIViewController+OBAContainment.h"
#import "OBAMapAnnotationViewBuilder.h"
#import "MKMapView+oba_Additions.h"
#import "ISHHoverBar.h"
#import "OBAToastView.h"

static const NSUInteger kShowNClosestStops = 4;
static const double kStopsInRegionRefreshDelayOnDrag = 0.1;

@interface OBAMapViewController ()<MKMapViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, MapSearchDelegate, OBANavigator>

// Map UI
@property(nonatomic,strong) MKMapView *mapView;
@property(nonatomic,strong) ISHHoverBar *locationHoverBar;
@property(nonatomic,strong) ISHHoverBar *secondaryHoverBar;
@property(nonatomic,strong) UIButton *mapTypeButton;
@property(nonatomic,strong) OBAToastView *toastView;

// Search
@property(nonatomic,strong) UISearchController *searchController;
@property(nonatomic,strong) MapSearchViewController *mapSearchResultsController;

// Programmatic UI
@property(nonatomic,strong) OBAMapActivityIndicatorView *mapActivityIndicatorView;
@property(nonatomic,strong) UIBarButtonItem *listBarButtonItem;
@property(nonatomic,strong) SVPulsingAnnotationView *userLocationAnnotationView;

// Everything Else
@property(nonatomic,assign) BOOL hideFutureOutOfRangeErrors;
@property(nonatomic,assign) BOOL hideFutureNetworkErrors;
@property(nonatomic,assign) BOOL doneLoadingMap;
@property(nonatomic,assign) MKCoordinateRegion mostRecentRegion;
@property(nonatomic,assign) NSUInteger mostRecentZoomLevel;
@property(nonatomic,strong) CLLocation *mostRecentLocation;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) OBAMapRegionManager *mapRegionManager;
@property(nonatomic,strong) OBAMapDataLoader *mapDataLoader;
@end

@implementation OBAMapViewController

- (id)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"msg_map", @"Map tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Map"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"Map_Selected"];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userHeadingDidUpdate:) name:OBAHeadingDidUpdateNotification object:nil];
    }

    return self;
}

- (void)dealloc {
    [self.mapDataLoader cancelOpenConnections];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createMapView];

    [self configureMapActivityIndicator];

    self.mostRecentRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0));

    // abxoxo - do this here or in the lazily loading property?
    self.mapDataLoader.delegate = self;

    self.mapRegionManager = [[OBAMapRegionManager alloc] initWithMapView:self.mapView];
    self.mapRegionManager.lastRegionChangeWasProgrammatic = YES;
    
    self.mapView.rotateEnabled = NO;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.mapView.showsUserLocation = YES;
    }

    [self createLocationHoverBar];
    [self createSecondaryHoverBar];

    self.hideFutureNetworkErrors = NO;

    if ([OBATheme useHighContrastUI]) {
        [self setHighContrastStyle];
    }
    else {
        [self setRegularStyle];
    }

    [self configureToastView];

    [self configureSearch];

    [self reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self refreshCurrentLocation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    OBALogFunction();

    [self registerForLocationNotifications];
    [self.locationManager startUpdatingHeading];

    if (self.mapDataLoader.unfilteredSearch) {
        [self refreshStopsInRegion];
    }

    NSString *placeholderText = NSLocalizedString(@"msg_search", @"");
    if (self.modelDAO.currentRegion.regionName) {
        placeholderText = [NSString stringWithFormat:NSLocalizedString(@"text_search_param",@"Search {Region Name}"), self.modelDAO.currentRegion.regionName];
    }

    self.searchController.searchBar.placeholder = placeholderText;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.locationManager stopUpdatingHeading];
    [self unregisterFromLocationNotifications];
}

#pragma mark - Search

- (void)configureSearch {
    self.mapSearchResultsController = [[MapSearchViewController alloc] init];
    self.mapSearchResultsController.delegate = self;

    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.mapSearchResultsController];
    self.searchController.delegate = self;
    self.searchController.searchResultsUpdater = self.mapSearchResultsController;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;

    // Search Bar
    self.searchController.searchBar.returnKeyType = UIReturnKeyDone;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.delegate = self;
    self.navigationItem.titleView = self.searchController.searchBar;
    [self.searchController.searchBar sizeToFit];

    self.definesPresentationContext = YES;
}

- (void)mapSearch:(MapSearchViewController *)mapSearch selectedNavigationTarget:(OBANavigationTarget *)target {
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Search button clicked" value:nil];
    NSString *analyticsLabel = [NSString stringWithFormat:@"Search: %@", NSStringFromOBASearchType(target.searchType)];
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:analyticsLabel value:nil];

    [self.searchController dismissViewControllerAnimated:YES completion:^{
        // abxoxo - TODO: figure out how to unify -navigateToTarget, this method, and -setNavigationTarget.
        if (target.searchType == OBASearchTypeStopId) {
            [self navigateToTarget:target];
            return;
        }

        self.mapDataLoader.searchRegion = [OBAMapHelpers convertVisibleMapRect:self.mapView.visibleMapRect intoCircularRegionWithCenter:self.mapView.centerCoordinate];

        [self setNavigationTarget:target];
    }];
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)searchController {
    dispatch_async(dispatch_get_main_queue(), ^{
        searchController.searchResultsController.view.hidden = NO;
    });
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    searchController.searchResultsController.view.hidden = NO;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Search box selected" value:nil];
}

#pragma mark - Lazily Loaded Properties

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (OBALocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager = [OBAApplication sharedApplication].locationManager;
    }
    return _locationManager;
}

- (OBAMapDataLoader*)mapDataLoader {
    if (!_mapDataLoader) {
        _mapDataLoader = [[OBAMapDataLoader alloc] initWithModelService:self.modelService];
        // abxoxo - do this here or in -viewDidLoad?
        // _mapDataLoader.delegate = self;
    }
    return _mapDataLoader;
}

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    if (OBASearchTypeRegion == self.mapDataLoader.searchType) {
        return [OBANavigationTarget navigationTargetForSearchLocationRegion:self.mapView.region];
    }
    else {
        return self.mapDataLoader.searchTarget;
    }
}

- (void)setNavigationTarget:(OBANavigationTarget *)target {
    if (OBASearchTypeRegion == target.searchType) {
        [self.mapDataLoader searchPending];
        [self.mapRegionManager setRegionFromNavigationTarget:target];
    }
    else {
        [self.mapDataLoader searchWithTarget:target];
    }
}

#pragma mark - OBAMapDataLoaderDelegate Methods

- (void)mapDataLoader:(OBAMapDataLoader*)mapDataLoader didUpdateResult:(OBASearchResult*)searchResult {
    [self reloadData];
}

- (void)mapDataLoader:(OBAMapDataLoader *)mapDataLoader didReceiveError:(NSError *)error {
    // We get this message because the user clicked "Don't allow" on using the current location.  Unfortunately,
    // this error gets propagated to us when the app isn't active (because the alert asking about location is).

    if (kCLErrorDomain == error.domain && kCLErrorDenied == error.code) {
        [self showLocationServicesAlert];
        return;
    }

    if (!self.controllerIsVisibleAndActive) {
        return;
    }

    DDLogError(@"%s - error: %@", __PRETTY_FUNCTION__, error);

    if ([error.domain isEqual:NSURLErrorDomain] || [error.domain isEqual:NSPOSIXErrorDomain]) {
        // We hide repeated network errors
        if (self.hideFutureNetworkErrors) {
            return;
        }

        self.hideFutureNetworkErrors = YES;

        [AlertPresenter showError:error];
    }
}

- (void)mapDataLoader:(OBAMapDataLoader*)mapDataLoader startedUpdatingWithNavigationTarget:(OBANavigationTarget*)target {
    [self.mapActivityIndicatorView setAnimating:YES];
}

- (void)mapDataLoaderFinishedUpdating:(OBAMapDataLoader*)searchController {
    [self.mapActivityIndicatorView setAnimating:NO];
}

#pragma mark - OBALocationManager Notifications

- (void)registerForLocationNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidUpdateLocation:) name:OBALocationDidUpdateNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidFailWithError:) name:OBALocationManagerDidFailWithErrorNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerDidChangeAuthorizationStatus:) name:OBALocationAuthorizationStatusChangedNotification object:nil];
}

- (void)unregisterFromLocationNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OBALocationDidUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OBALocationManagerDidFailWithErrorNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OBALocationAuthorizationStatusChangedNotification object:nil];
}

- (void)locationManagerDidUpdateLocation:(NSNotification*)note {
    [self refreshCurrentLocation];
}

- (void)locationManagerDidFailWithError:(NSNotification*)note {
    NSError *error = note.userInfo[OBALocationErrorUserInfoKey];
    if (kCLErrorDomain == error.domain && kCLErrorDenied == error.code) {
        [self showLocationServicesAlert];
    }
}

- (void)locationManagerDidChangeAuthorizationStatus:(NSNotification*)note {
    CLAuthorizationStatus status = (CLAuthorizationStatus)[note.userInfo[OBALocationAuthorizationStatusUserInfoKey] integerValue];
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.mapView.showsUserLocation = YES;
    }
}

#pragma mark - MKMapViewDelegate Methods

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    self.doneLoadingMap = YES;
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

    if (self.mapDataLoader.unfilteredSearch) {
        NSTimeInterval interval = kStopsInRegionRefreshDelayOnDrag;
        CLLocation *location = nil;
        if (self.mapRegionManager.lastRegionChangeWasProgrammatic) {
            interval = [self.class refreshIntervalForLocationAccuracy:self.locationManager.currentLocation];
            location = self.locationManager.currentLocation;
        }
        [self scheduleRefreshOfStopsInRegion:interval location:location];
    }

    [OBAMapAnnotationViewBuilder scaleAnnotationsOnMapView:mapView forSearchResult:self.mapDataLoader.result];
}

- (void)userHeadingDidUpdate:(NSNotification*)note {
    if (!self.userLocationAnnotationView) {
        return;
    }

    CLHeading *heading = note.userInfo[OBAHeadingUserInfoKey];
    [self updateUserLocationAnnotationViewWithHeading:heading];
}

- (void)updateUserLocationAnnotationViewWithHeading:(CLHeading*)heading {
    _userLocationAnnotationView.headingImageView.hidden = NO;
    // The SVPulsingAnnotationView assumes east == 0. Because different coordinate systems :(
    NSInteger adjustedDegrees = (NSInteger)(heading.trueHeading - 90) % 360;
    CGFloat radians = [OBAImageHelpers degreesToRadians:(CGFloat)adjustedDegrees];
    _userLocationAnnotationView.headingImageView.transform = CGAffineTransformMakeRotation(radians);
}

- (void)buildUserLocationAnnotationViewForAnnotation:(id<MKAnnotation>)annotation heading:(nullable CLHeading*)heading {
    if (!_userLocationAnnotationView) {
        _userLocationAnnotationView = [[SVPulsingAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"SVPulsingAnnotationView" size:CGSizeMake(24, 24)];
        _userLocationAnnotationView.annotationColor = [OBATheme userLocationFillColor];
        _userLocationAnnotationView.canShowCallout = NO;
        _userLocationAnnotationView.headingImage = [UIImage imageNamed:@"userHeading"];
    }

    if (heading) {
        [self updateUserLocationAnnotationViewWithHeading:heading];
    }
    else {
        _userLocationAnnotationView.headingImageView.hidden = YES;
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        [self buildUserLocationAnnotationViewForAnnotation:annotation heading:self.locationManager.currentHeading];
        return self.userLocationAnnotationView;
    }
    else if ([annotation isKindOfClass:[OBAStopV2 class]]) {
        return [OBAMapAnnotationViewBuilder mapView:mapView annotationViewForStop:(OBAStopV2*)annotation withSearchType:self.mapDataLoader.result.searchType];
    }
    else if ([annotation isKindOfClass:[OBABookmarkV2 class]]) {
        return [OBAMapAnnotationViewBuilder mapView:mapView annotationViewForBookmark:(OBABookmarkV2*)annotation];
    }
    else if ([annotation isKindOfClass:[OBAPlacemark class]]) {
        return [OBAMapAnnotationViewBuilder mapView:mapView viewForPlacemark:(OBAPlacemark*)annotation withSearchType:self.mapDataLoader.result.searchType];
    }
    else if ([annotation isKindOfClass:[OBANavigationTargetAnnotation class]]) {
        return [OBAMapAnnotationViewBuilder mapView:mapView viewForNavigationTarget:annotation];
    }

    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    id annotation = view.annotation;

    if ([annotation respondsToSelector:@selector(stopId)]) {
        OBAStopViewController *stopController = [[OBAStopViewController alloc] initWithStopID:[annotation stopId]];
        [self.navigationController pushViewController:stopController animated:YES];
    }
    else if ([annotation isKindOfClass:[OBAPlacemark class]]) {
        OBAPlacemark *placemark = annotation;
        OBANavigationTarget *target = [OBANavigationTarget navigationTargetForSearchPlacemark:placemark];
        [self.mapDataLoader searchWithTarget:target];
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
        return [[MKOverlayRenderer alloc] init];
    }
}

#pragma mark - Actions

- (IBAction)updateLocation:(id)sender {
    if (!self.locationManager.locationServicesEnabled) {
        UIAlertController *alert = [OBAAlerts locationServicesDisabledAlert];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked My Location Button" value:nil];
    DDLogInfo(@"setting auto center on current location");
    self.mapRegionManager.lastRegionChangeWasProgrammatic = YES;
    [self refreshCurrentLocation];
}

- (void)recenterMap {
    if (!self.isViewLoaded || !self.view.window) {
        return;
    }

    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"My Location via Map Tab Button" value:nil];
    DDLogInfo(@"setting auto center on current location (via tab bar)");
    self.mapRegionManager.lastRegionChangeWasProgrammatic = YES;
    [self refreshCurrentLocation];
}

// More map options such as Satellite views
// see https://github.com/OneBusAway/onebusaway-iphone/issues/65
- (IBAction)changeMapTypes {
    if (self.mapView.mapType == MKMapTypeStandard) {
        self.mapView.mapType = MKMapTypeHybrid;
    }
    else {
        self.mapView.mapType = MKMapTypeStandard;
    }
    self.mapTypeButton.selected = self.mapView.mapType == MKMapTypeHybrid;
    [[NSUserDefaults standardUserDefaults] setInteger:self.mapView.mapType forKey:OBAMapSelectedTypeDefaultsKey];
}

- (IBAction)showNearbyStops {
    OBASearchResult *result = [self.mapDataLoader.result resultsInRegion:self.mapView.region];
    [self showNearbyStopsWithSearchResult:result];
}

- (void)cancelCurrentSearch {
    self.searchController.searchBar.text = nil;
    [self.mapDataLoader searchWithTarget:[OBANavigationTarget navigationTargetForSearchNone]];
    [self refreshStopsInRegion];
}

#pragma mark - Nearby Stops/OBANavigator

- (void)showNearbyStopsWithSearchResult:(OBASearchResult*)searchResult {
    NearbyStopsViewController *nearbyStops = [[NearbyStopsViewController alloc] init:searchResult];
    nearbyStops.presentedModally = YES;
    nearbyStops.navigator = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:nearbyStops];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)navigateToTarget:(OBANavigationTarget*)navigationTarget {
    if (navigationTarget.searchType == OBASearchTypeStopId) {
        CLCircularRegion *circularRegion = [OBAMapHelpers convertVisibleMapRect:self.mapView.visibleMapRect intoCircularRegionWithCenter:self.mapView.centerCoordinate];

        [SVProgressHUD show];
        [self.modelService requestStopsForQuery:navigationTarget.searchArgument region:circularRegion].then(^(OBASearchResult *searchResult) {
            [self displayStopControllerForSearchResult:searchResult];
        }).always(^{
            [SVProgressHUD dismiss];
        });
    }
    else {
        [APP_DELEGATE navigateToTarget:navigationTarget];
    }
}

- (void)displayStopControllerForSearchResult:(OBASearchResult*)searchResult {
    if (searchResult.values.count == 0) {
        [AlertPresenter showWarning:NSLocalizedString(@"map_controller.no_matching_stop_warning_title", @"Error title displayed when the stop ID provided doesn't match a known stop ID.") body:NSLocalizedString(@"map_controller.no_matching_stop_warning_body", @"Error message displayed when the stop ID provided doesn't match a known stop ID.")];
        return;
    }

    if (searchResult.values.count > 1) {
        [self showNearbyStopsWithSearchResult:searchResult];
        return;
    }

    OBAStopV2 *stop = searchResult.values.firstObject;
    OBAStopViewController *stopController = [[OBAStopViewController alloc] initWithStopID:stop.stopId];
    [self.navigationController pushViewController:stopController animated:YES];
}

#pragma mark - OBASearchMapViewController Private Methods

- (void)refreshCurrentLocation {
    CLLocation *location = self.locationManager.currentLocation;

    if (location) {
        if (self.mapRegionManager.lastRegionChangeWasProgrammatic) {
            double radius = MAX(location.horizontalAccuracy, OBAMinMapRadiusInMeters);
            MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:location.coordinate latRadius:radius lonRadius:radius];
            [self.mapRegionManager setRegion:region changeWasProgrammatic:YES];
        }
    }
    else if (self.modelDAO.currentRegion) {
        MKCoordinateRegion coordinateRegion = MKCoordinateRegionForMapRect(self.modelDAO.currentRegion.serviceRect);
        [self.mapRegionManager setRegion:coordinateRegion changeWasProgrammatic:YES];
    }
}

- (void)scheduleRefreshOfStopsInRegion:(NSTimeInterval)interval location:(CLLocation *)location {
    MKCoordinateRegion region = self.mapView.region;

    BOOL moreAccurateRegion = self.mostRecentLocation != nil && location != nil && location.horizontalAccuracy < self.mostRecentLocation.horizontalAccuracy;
    BOOL containedRegion = [OBASphericalGeometryLibrary isRegion:region containedBy:self.mostRecentRegion];

    BOOL zoomLevelChanged = (ABS((int) self.mostRecentZoomLevel - (int) self.mapView.oba_zoomLevel) >= OBARegionZoomLevelThreshold);

    DDLogInfo(@"scheduleRefreshOfStopsInRegion: %f %d %d", interval, moreAccurateRegion, containedRegion);

    if (!moreAccurateRegion && containedRegion && !zoomLevelChanged) {
        [self showToastViewWithTextForCurrentResults];
        return;
    }

    self.mostRecentLocation = location;
    self.mostRecentZoomLevel = self.mapView.oba_zoomLevel;

    [self.refreshTimer invalidate];
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refreshStopsInRegion) userInfo:nil repeats:NO];
}

+ (NSTimeInterval)refreshIntervalForLocationAccuracy:(CLLocation *)location {
    if (location == nil) {
        return kStopsInRegionRefreshDelayOnDrag;
    }

    if (location.horizontalAccuracy < 20) {
        return 0;
    }

    if (location.horizontalAccuracy < 200) {
        return 0.25;
    }

    if (location.horizontalAccuracy < 500) {
        return 0.5;
    }

    if (location.horizontalAccuracy < 1000) {
        return 1;
    }

    return 1.5;
}

- (void)refreshStopsInRegion {
    self.refreshTimer = nil;

    MKCoordinateRegion region = self.mapView.region;
    MKCoordinateSpan span = region.span;

    OBANavigationTarget *target = nil;

    if (span.latitudeDelta > OBAMaxLatitudeDeltaToShowStops) {
        // Reset the most recent region
        self.mostRecentRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0));
        target = [OBANavigationTarget navigationTargetForSearchNone];
    }
    else {
        span.latitudeDelta  *= OBARegionScaleFactor;
        span.longitudeDelta *= OBARegionScaleFactor;
        region.span = span;

        self.mostRecentRegion = region;

        target = [OBANavigationTarget navigationTargetForSearchLocationRegion:region];
    }

    [self.mapDataLoader searchWithTarget:target];
}

- (void)reloadData {
    OBASearchResult *result = self.mapDataLoader.result;

    if (result && result.searchType == OBASearchTypeRoute && [result.values count] > 0) {
        [self showNearbyStopsWithSearchResult:result];
        return;
    }

    [OBAMapAnnotationViewBuilder updateAnnotationsOnMapView:self.mapView fromSearchResult:self.mapDataLoader.result bookmarkAnnotations:self.modelDAO.mappableBookmarksForCurrentRegion];
    [OBAMapAnnotationViewBuilder setOverlaysOnMapView:self.mapView fromSearchResult:self.mapDataLoader.result];
    [self setRegionFromResults];

    [self showToastViewWithTextForCurrentResults];

    [self checkResults];

    if (self.doneLoadingMap && self.modelDAO.currentRegion && [self outOfServiceArea]) {
        [self showOutOfRangeAlert];
    }
}

- (CLLocation *)currentLocation {
    if (self.locationManager.currentLocation) {
        return self.locationManager.currentLocation;
    }

    CLLocation *loc = self.mapDataLoader.searchLocation;
    if (loc) {
        return loc;
    }

    return [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude];
}

- (void)showOutOfRangeAlert {
    if (self.hideFutureOutOfRangeErrors) {
        return;
    }

    NSString *regionName = self.modelDAO.currentRegion.regionName;
    NSString *alertTitle = [NSString stringWithFormat:NSLocalizedString(@"text_ask_go_to_region_param", @"Out of range alert title"), regionName];
    NSString *alertMessage = [NSString stringWithFormat:NSLocalizedString(@"text_ask_go_to_service_area_param", @"Out of range alert message"), regionName];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.hideFutureOutOfRangeErrors = YES;
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Out of Region Alert: NO" value:nil];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.ok style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Out of Region Alert: YES" value:nil];
        [self.mapRegionManager setRegion:MKCoordinateRegionForMapRect(self.modelDAO.currentRegion.serviceRect)];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showLocationServicesAlert {
    if (self.modelDAO.hideFutureLocationWarnings) {
        return;
    }

    self.modelDAO.hideFutureLocationWarnings = YES;
    UIAlertController *alert = [OBAAlerts locationServicesDisabledAlert];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToastViewWithTextForCurrentResults {
    OBASearchResult *result = self.mapDataLoader.result;
    OBANavigationTarget *navigationTarget = self.mapDataLoader.searchTarget;
    MKCoordinateSpan span = self.mapView.region.span;

    NSString *toastText = nil;
    BOOL showCancel = NO;

    if (span.latitudeDelta > OBAMaxLatitudeDeltaToShowStops) {
        toastText = NSLocalizedString(@"msg_zoom_on_map_for_look_stop", @"span.latitudeDelta > kMaxLatDeltaToShowStops");
    }

    switch (result.searchType) {
        case OBASearchTypeRoute:
        case OBASearchTypeStops:
        case OBASearchTypeAddress:
        case OBASearchTypeStopId: {
            NSString *query = navigationTarget.userFacingSearchQuery;

            if (!query) {
                NSString *searchTypeString = NSStringFromOBASearchType(result.searchType);
                query = [NSString stringWithFormat:@"%@: %@", searchTypeString, self.mapDataLoader.searchTarget.parameters[OBANavigationTargetSearchKey]];
            }

            toastText = query;
            showCancel = YES;
        }

        case OBASearchTypePlacemark:
        case OBASearchTypeRegion: {
            if (![self checkStopsInRegion] && span.latitudeDelta <= OBAMaxLatitudeDeltaToShowStops) {
                toastText = NSLocalizedString(@"msg_no_stops_location_map", @"[values count] == 0");
            }

            break;
        }

        case OBASearchTypePending:
        case OBASearchTypeNone:
            break;
    }

    if (self.modelDAO.currentRegion && [self outOfServiceArea]) {
        toastText = NSLocalizedString(@"msg_out_oba_service_area", @"result.outOfRange");
    }

    if (toastText) {
        [self.toastView showWithText:toastText withCancelButton:showCancel];
    }
    else {
        [self.toastView dismiss];
    }
}

- (void)setRegionFromResults {
    BOOL needsUpdate = NO;
    MKCoordinateRegion region = [self computeRegionForCurrentResults:&needsUpdate];

    if (needsUpdate) {
        DDLogInfo(@"setRegionFromResults");
        [self.mapRegionManager setRegion:region changeWasProgrammatic:NO];
    }
}

- (MKCoordinateRegion)computeRegionForCurrentResults:(BOOL *)needsUpdate {
    *needsUpdate = YES;

    OBASearchResult *result = self.mapDataLoader.result;

    if (!result || (result.values.count == 0 && result.additionalValues.count == 0)) {
        *needsUpdate = NO;
        return self.mapView.region;
    }

    switch (result.searchType) {
        case OBASearchTypeStopId:
            return [OBAMapHelpers computeRegionForNClosestStops:result.values center:[self currentLocation] numberOfStops:kShowNClosestStops];

        case OBASearchTypeRoute:
        case OBASearchTypeStops:
            return [OBAMapHelpers computeRegionForCenter:[self currentLocation] nearbyStops:result.values];

        case OBASearchTypePlacemark:
            return [self computeRegionForPlacemarks:result.additionalValues andStops:result.values];

        case OBASearchTypeAddress:
            return [OBAMapHelpers computeRegionForPlacemarks:result.values defaultRegion:self.mapView.region];

        case OBASearchTypeNone:
        case OBASearchTypeRegion:
        default:
            *needsUpdate = NO;
            return self.mapView.region;
    }
}

// TODO: Figure out what's going on here. This method looks broken.
- (MKCoordinateRegion)computeRegionForPlacemarks:(NSArray *)placemarks andStops:(NSArray *)stops {
    CLLocation *center = [self currentLocation];

    for (OBAPlacemark *placemark in placemarks) {
        CLLocationCoordinate2D coordinate = placemark.coordinate;
        center = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    }

    return [OBAMapHelpers computeRegionForNClosestStops:stops center:center numberOfStops:kShowNClosestStops];
}

- (void)checkResults {
    OBASearchResult *result = self.mapDataLoader.result;

    if (!result) {
        return;
    }

    if (!self.controllerIsVisibleAndActive) {
        return;
    }

    if (self.mapDataLoader.result.outOfRange) {
        [self showOutOfRangeAlert];
        return;
    }

    if (self.mapDataLoader.result.values.count > 0) {
        return;
    }

    NSString *alertTitle = nil;
    NSString *alertMessage = nil;

    if (OBASearchTypeRoute == result.searchType) {
        alertTitle = NSLocalizedString(@"msg_no_routes_found", @"showNoResultsAlertWithTitle");
        alertMessage = NSLocalizedString(@"msg_explanatory_no_routes_found", @"prompt");
    }
    else if (OBASearchTypeAddress == result.searchType) {
        alertTitle = NSLocalizedString(@"msg_no_places_found", @"showNoResultsAlertWithTitle");
        alertMessage = NSLocalizedString(@"msg_explanatory_no_places_found", @"prompt");
    }
    else if (OBASearchTypeStopId == result.searchType) {
        alertTitle = NSLocalizedString(@"msg_minus_no_stops_found", @"showNoResultsAlertWithTitle");
        alertMessage = NSLocalizedString(@"msg_explanatory_minus_no_stops_found", @"prompt");
    }

    if (alertTitle && alertMessage) {
        [AlertPresenter showWarning:alertTitle body:alertMessage];
    }
}

- (BOOL)controllerIsVisibleAndActive {
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return NO;
    }

    // Ignore errors if our view isn't currently on top
    return self == self.navigationController.visibleViewController;
}

- (BOOL)outOfServiceArea {
    return [OBAMapHelpers visibleMapRect:self.mapView.visibleMapRect isOutOfServiceArea:self.modelDAO.currentRegion.bounds];
}

- (BOOL)checkStopsInRegion {
    if ([[self.mapView annotationsInMapRect:self.mapView.visibleMapRect] count] > 0) {
        return YES;
    }

    NSMutableArray *annotations = [NSMutableArray arrayWithArray:[self.mapView annotations]];

    if (self.mapView.userLocation) {
        [annotations removeObject:self.mapView.userLocation];
    }

    for (id<MKAnnotation> annotation in annotations) {
        MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annotation];
        MKCoordinateRegion annotationRegion = [self.mapView convertRect:annotationView.frame toRegionFromView:self.mapView];
        MKMapRect annotationRect = [OBAMapHelpers mapRectForCoordinateRegion:annotationRegion];

        if (MKMapRectIntersectsRect(self.mapView.visibleMapRect, annotationRect)) {
            return YES;
        }
    }

    return NO;
}

#pragma mark - UI Configuration

- (void)createMapView {
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
}

- (void)configureMapActivityIndicator {
    CGRect indicatorBounds = CGRectMake(12, 12, 36, 36);
    indicatorBounds.origin.y += self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;

    self.mapActivityIndicatorView = [[OBAMapActivityIndicatorView alloc] initWithFrame:indicatorBounds];
    self.mapActivityIndicatorView.hidden = YES;
    [self.view addSubview:self.mapActivityIndicatorView];
}

- (void)configureToastView {
    self.toastView = [[OBAToastView alloc] initWithFrame:CGRectZero];
    [self.toastView.button addTarget:self action:@selector(cancelCurrentSearch) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toastView];
    [self.toastView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.mas_topLayoutGuideBottom).offset([OBATheme defaultPadding]);
        make.width.lessThanOrEqualTo(@500).priorityMedium();
        make.left.and.right.lessThanOrEqualTo(self.view).insets(UIEdgeInsetsMake(0, 20, 0, 20)).priorityHigh();
    }];
}

- (void)createLocationHoverBar {
    UIBarButtonItem *recenterMapButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Map_Selected"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(recenterMap)];

    self.locationHoverBar = [[ISHHoverBar alloc] init];
    self.locationHoverBar.items = @[recenterMapButton];
    [self.view addSubview:self.locationHoverBar];
    [self.locationHoverBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.and.trailing.equalTo(self.mapView).insets(UIEdgeInsetsMake(0, 0, 64, 16));
    }];
}

- (void)createSecondaryHoverBar {
    self.secondaryHoverBar = [[ISHHoverBar alloc] init];

    UIBarButtonItem *nearby = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"lines"] style:UIBarButtonItemStylePlain target:self action:@selector(showNearbyStops)];
    nearby.accessibilityLabel = NSLocalizedString(@"msg_nearby_stops_list", @"self.listBarButtonItem.accessibilityLabel");

    // Create Map Type Toggle Button
    self.mapTypeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [self.mapTypeButton setImage:[UIImage imageNamed:@"satelliteMapIcon"] forState:UIControlStateNormal];
    [self.mapTypeButton setImage:[UIImage imageNamed:@"standardMapIcon"] forState:UIControlStateSelected];
    self.mapTypeButton.imageEdgeInsets = [OBATheme compactEdgeInsets];
    [self.mapTypeButton addTarget:self action:@selector(changeMapTypes) forControlEvents:UIControlEventTouchUpInside];

    // Create Bar Button Item
    UIBarButtonItem *mapBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.mapTypeButton];
    // Configure the default map display style
    // see https://github.com/OneBusAway/onebusaway-iphone/issues/65
    self.mapView.mapType = [[NSUserDefaults standardUserDefaults] integerForKey:OBAMapSelectedTypeDefaultsKey];
    self.mapTypeButton.selected = self.mapView.mapType == MKMapTypeHybrid;

    self.secondaryHoverBar.items = @[nearby, mapBarButton];

    [self.view addSubview:self.secondaryHoverBar];
    [self.secondaryHoverBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.locationHoverBar.mas_top).offset(-2 * [OBATheme defaultPadding]);
        make.trailing.equalTo(self.locationHoverBar);
    }];
}

#pragma mark - Private Configuration Junk

- (void)setHighContrastStyle {
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAccessibility action:@"increase_contrast" label:[NSString stringWithFormat:@"Loaded view: %@ with Increased Contrast", [self class]] value:nil];

    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.tabBarController.tabBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}

- (void)setRegularStyle {
    self.navigationController.navigationBar.barTintColor = nil;
    self.navigationController.tabBarController.tabBar.barTintColor = nil;
    self.navigationController.navigationBar.tintColor = [OBATheme OBAGreen];
}

@end
