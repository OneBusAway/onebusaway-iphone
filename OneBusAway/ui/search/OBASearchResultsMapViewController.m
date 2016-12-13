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
@import OBAKit;
#import "OBASearchResultsListViewController.h"
#import "OBAStopViewController.h"
#import "OBAAnalytics.h"
#import "OBAAlerts.h"
#import "OBAAnimation.h"
#import "OBAMapActivityIndicatorView.h"
@import Masonry;
#import "OBAVibrantBlurContainerView.h"

#define kRouteSegmentIndex          0
#define kAddressSegmentIndex        1
#define kStopNumberSegmentIndex     2

#define kDefaultTitle NSLocalizedString(@"msg_map", @"Map tab title")

static const NSUInteger kShowNClosestStops = 4;
static const double kStopsInRegionRefreshDelayOnDrag = 0.1;

@interface OBASearchResultsMapViewController ()<MKMapViewDelegate, UISearchBarDelegate>

// IB UI
@property(nonatomic,strong) IBOutlet OBAScopeView *scopeView;
@property(nonatomic,strong) IBOutlet UISegmentedControl *searchTypeSegmentedControl;
@property(nonatomic,strong) IBOutlet MKMapView * mapView;
@property(nonatomic,strong) IBOutlet UISearchBar *searchBar;
@property(nonatomic,strong) IBOutlet UILabel *mapLabel;
@property(nonatomic,strong) UIView *mapLabelContainer;

// Programmatic UI
@property(nonatomic,strong) OBAMapActivityIndicatorView *mapActivityIndicatorView;
@property(nonatomic,strong) UIBarButtonItem *listBarButtonItem;
@property(nonatomic,strong) UIView *titleView;
@property(nonatomic,strong) MKUserTrackingBarButtonItem *trackingBarButtonItem;

// Everything Else
@property(nonatomic,assign) BOOL hideFutureOutOfRangeErrors;
@property(nonatomic,assign) BOOL hideFutureNetworkErrors;
@property(nonatomic,assign) BOOL doneLoadingMap;
@property(nonatomic,assign) MKCoordinateRegion mostRecentRegion;
@property(nonatomic,assign) NSUInteger mostRecentZoomLevel;
@property(nonatomic,strong) CLLocation *mostRecentLocation;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) OBAMapRegionManager *mapRegionManager;
@property(nonatomic,strong) OBASearchController *searchController;
@property(nonatomic,assign) BOOL secondSearchTry;
@property(nonatomic,strong) OBANavigationTarget *savedNavigationTarget;
@end

@implementation OBASearchResultsMapViewController

- (id)init {
    self = [super initWithNibName:@"OBASearchResultsMapViewController" bundle:nil];

    if (self) {
        self.title = kDefaultTitle;
        self.tabBarItem.image = [UIImage imageNamed:@"Map"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"Map_Selected"];
    }

    return self;
}

- (void)dealloc {
    [self.searchController cancelOpenConnections];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureMapActivityIndicator];

    CLLocationCoordinate2D p = CLLocationCoordinate2DMake(0, 0);
    self.mostRecentRegion = MKCoordinateRegionMake(p, MKCoordinateSpanMake(0, 0));

    self.refreshTimer = nil;

    self.mapRegionManager = [[OBAMapRegionManager alloc] initWithMapView:self.mapView];
    self.mapRegionManager.lastRegionChangeWasProgrammatic = YES;
    
    self.mapView.rotateEnabled = NO;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.mapView.showsUserLocation = YES;
    }

    self.hideFutureNetworkErrors = NO;

    self.searchController = [[OBASearchController alloc] initWithModelService:self.modelService];
    self.searchController.delegate = self;
    self.searchController.progress.delegate = self;

    if (self.savedNavigationTarget) {
        [self.searchController searchWithTarget:self.savedNavigationTarget];
        self.savedNavigationTarget = nil;
    }

    [self configureNavigationBar];

    if ([OBATheme useHighContrastUI]) {
        [self setHighContrastStyle];
    }
    else {
        [self setRegularStyle];
    }

    [self configureMapLabel];
}

- (void)configureMapActivityIndicator {
    CGRect indicatorBounds = CGRectMake(12, 12, 36, 36);
    indicatorBounds.origin.y += self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;

    self.mapActivityIndicatorView = [[OBAMapActivityIndicatorView alloc] initWithFrame:indicatorBounds];
    self.mapActivityIndicatorView.hidden = YES;
    [self.view addSubview:self.mapActivityIndicatorView];
}

- (void)configureNavigationBar {
    self.navigationItem.leftBarButtonItem = self.trackingBarButtonItem;

    self.listBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"lines"] style:UIBarButtonItemStylePlain target:self action:@selector(showListView:)];
    self.listBarButtonItem.accessibilityLabel = NSLocalizedString(@"msg_nearby_stops_list", @"self.listBarButtonItem.accessibilityLabel");
    self.navigationItem.rightBarButtonItem = self.listBarButtonItem;

    self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    self.searchBar = ({
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        searchBar.searchBarStyle = UISearchBarStyleMinimal;
        searchBar.placeholder = NSLocalizedString(@"msg_search", @"");
        searchBar.delegate = self;
        searchBar;
    });
    [self.titleView addSubview:self.searchBar];
    [self.searchBar sizeToFit];
    self.navigationItem.titleView = self.titleView;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self refreshCurrentLocation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    OBALogFunction();

    [self registerForLocationNotifications];
    [[OBAApplication sharedApplication].locationManager startUpdatingLocation];

    if (self.searchController.unfilteredSearch) {
        [self refreshStopsInRegion];
    }
    
    if ([OBAApplication sharedApplication].modelDao.currentRegion.regionName) {
        self.searchBar.placeholder = [NSString stringWithFormat:NSLocalizedString(@"text_search_param",@"Search {Region Name}"), [OBAApplication sharedApplication].modelDao.currentRegion.regionName];
    }
    else {
        self.searchBar.placeholder = NSLocalizedString(@"msg_search", @"");
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[OBAApplication sharedApplication].locationManager stopUpdatingLocation];
    [self unregisterFromLocationNotifications];
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
    [self.navigationItem setLeftBarButtonItem:self.trackingBarButtonItem animated:YES];
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
    self.searchController.searchRegion = [OBAMapHelpers convertVisibleMapRect:self.mapView.visibleMapRect intoCircularRegionWithCenter:self.mapView.centerCoordinate];

    NSString *analyticsLabel = nil;

    if (kRouteSegmentIndex == self.searchTypeSegmentedControl.selectedSegmentIndex) {
        target = [OBASearch getNavigationTargetForSearchRoute:searchBar.text];
        analyticsLabel = @"Search: Route";
    }
    else if (kAddressSegmentIndex == self.searchTypeSegmentedControl.selectedSegmentIndex) {
        target = [OBASearch getNavigationTargetForSearchAddress:searchBar.text];
        analyticsLabel = @"Search: Address";
    }
    else {
        target = [OBASearch getNavigationTargetForSearchStopCode:searchBar.text];
        analyticsLabel = @"Search: Stop";
    }
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:analyticsLabel value:nil];

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

    [OBAAnimation performAnimations:^{
        self.scopeView.frame = finalScopeFrame;
    }];
}

- (void)animateOutScopeView {
    CGRect offscreenScopeFrame = self.scopeView.frame;

    offscreenScopeFrame.origin.y = -offscreenScopeFrame.size.height;

    [OBAAnimation performAnimations:^{
        self.scopeView.frame = offscreenScopeFrame;
    } completion:^(BOOL finished) {
        [self.scopeView removeFromSuperview];
    }];
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
    OBASearchType searchType = [OBASearch getSearchTypeForNavigationTarget:target];

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

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_error_min_connecting", @"self.navigationItem.title") message:NSLocalizedString(@"msg_problem_internet_connection_on_map", @"view.message") preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_contact_us", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [APP_DELEGATE navigateToTarget:[OBANavigationTarget navigationTarget:OBANavigationTargetTypeContactUs]];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
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

#pragma mark - OBAProgressIndicatorDelegate

- (void)progressUpdated {
    id<OBAProgressIndicatorSource> progress = self.searchController.progress;
    [self.mapActivityIndicatorView setAnimating:progress.inProgress];
}

#pragma mark - MKMapViewDelegate Methods

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
            NSTimeInterval refreshInterval = [self.class refreshIntervalForLocationAccuracy:lm.currentLocation];
            [self scheduleRefreshOfStopsInRegion:refreshInterval location:lm.currentLocation];
        }
        else {
            [self scheduleRefreshOfStopsInRegion:kStopsInRegionRefreshDelayOnDrag location:nil];
        }
    }

    CGFloat scale = 1.f;
    CGFloat alpha = 1.f;

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

+ (MKAnnotationView*)viewForAnnotation:(id<MKAnnotation>)annotation forMapView:(MKMapView*)mapView {

    NSString *reuseIdentifier = NSStringFromClass([annotation class]);

    MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];

    if (!view) {
        view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    }

    view.canShowCallout = YES;
    view.rightCalloutAccessoryView = ({
        UIButton *rightCalloutButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        if ([OBATheme useHighContrastUI]) {
            rightCalloutButton.tintColor = [UIColor blackColor];
        }
        else {
            rightCalloutButton.tintColor = [OBATheme OBAGreen];
        }
        rightCalloutButton;
    });

    return view;
}

- (MKAnnotationView*)mapView:(MKMapView*)mapView annotationViewForStop:(OBAStopV2*)stop {
    MKAnnotationView *view = [self.class viewForAnnotation:stop forMapView:mapView];
    OBASearchResult *result = self.searchController.result;

    if (OBASearchTypeRouteStops == result.searchType) {
        CGFloat scale = [OBASphericalGeometryLibrary computeStopsForRouteAnnotationScaleFactor:mapView.region];
        CGFloat alpha = scale <= 0.11f ? 0.f : 1.f;

        view.transform = CGAffineTransformMakeScale(scale, scale);
        view.alpha = alpha;
    }

    view.image = [OBAStopIconFactory getIconForStop:stop];

    return view;
}

- (MKAnnotationView*)mapView:(MKMapView*)mapView annotationViewForBookmark:(OBABookmarkV2*)bookmark {
    MKAnnotationView *view = [self.class viewForAnnotation:bookmark forMapView:mapView];

    UIImage *stopImage = nil;

    if (bookmark.stop) {
        stopImage = [OBAStopIconFactory getIconForStop:bookmark.stop];
        stopImage = [OBAImageHelpers colorizeImage:stopImage withColor:[OBATheme mapBookmarkTintColor]];
    }
    else {
        stopImage = [UIImage imageNamed:@"Bookmarks"];
    }

    view.image = stopImage;

    return view;
}

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForPlacemark:(OBAPlacemark*)placemark {
    static NSString *viewId = @"NavigationTargetView";
    MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

    if (!view) {
        view = [[MKPinAnnotationView alloc] initWithAnnotation:placemark reuseIdentifier:viewId];
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

- (MKAnnotationView*)mapView:(MKMapView *)mapView viewForNavigationTarget:(OBANavigationTargetAnnotation*)annotation {
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

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[OBAStopV2 class]]) {
        return [self mapView:mapView annotationViewForStop:(OBAStopV2*)annotation];
    }
    else if ([annotation isKindOfClass:[OBABookmarkV2 class]]) {
        return [self mapView:mapView annotationViewForBookmark:(OBABookmarkV2*)annotation];
    }
    else if ([annotation isKindOfClass:[OBAPlacemark class]]) {
        return [self mapView:mapView viewForPlacemark:(OBAPlacemark*)annotation];
    }
    else if ([annotation isKindOfClass:[OBANavigationTargetAnnotation class]]) {
        return [self mapView:mapView viewForNavigationTarget:annotation];
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
        return [[MKOverlayRenderer alloc] init];
    }
}

#pragma mark - IBActions

- (IBAction)updateLocation:(id)sender {

    OBALocationManager *lm = [OBAApplication sharedApplication].locationManager;

    if (lm.locationServicesEnabled) {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked My Location Button" value:nil];
        DDLogInfo(@"setting auto center on current location");
        self.mapRegionManager.lastRegionChangeWasProgrammatic = YES;
        [self refreshCurrentLocation];
    }
    else {
        UIAlertController *alert = [OBAAlerts locationServicesDisabledAlert];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)recenterMap {
    if (self.isViewLoaded && self.view.window) {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"My Location via Map Tab Button" value:nil];
        DDLogInfo(@"setting auto center on current location (via tab bar)");
        self.mapRegionManager.lastRegionChangeWasProgrammatic = YES;
        [self refreshCurrentLocation];
    }
}

- (IBAction)showListView:(id)sender {
    OBASearchResult * __nonnull result = self.searchController.result;

    if (result) {
        // Prune down the results to show only what's currently in the map view
        result = [result resultsInRegion:self.mapView.region];
    }

    OBASearchResultsListViewController *listViewController = [[OBASearchResultsListViewController alloc] init];
    listViewController.result = result;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:listViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - OBASearchMapViewController Private Methods

- (void)refreshCurrentLocation {
    OBALocationManager *lm = [OBAApplication sharedApplication].locationManager;
    CLLocation *location = lm.currentLocation;

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

    NSUInteger zoomLevel = [OBAMapHelpers zoomLevelForMapRect:self.mapView.visibleMapRect withMapViewSizeInPixels:self.mapView.frame.size];
    BOOL zoomLevelChanged = (ABS((int) self.mostRecentZoomLevel - (int) zoomLevel) >= OBARegionZoomLevelThreshold);

    DDLogInfo(@"scheduleRefreshOfStopsInRegion: %f %d %d", interval, moreAccurateRegion, containedRegion);

    if (!moreAccurateRegion && containedRegion && !zoomLevelChanged) {
        NSString *label = [self computeLabelForCurrentResults];
        [self applyMapLabelWithText:label];
        return;
    }

    self.mostRecentLocation = location;
    self.mostRecentZoomLevel = zoomLevel;

    if (self.refreshTimer) {
        [self.refreshTimer invalidate];
    }

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

    if (span.latitudeDelta > OBAMaxLatitudeDeltaToShowStops) {
        // Reset the most recent region
        CLLocationCoordinate2D p = { 0, 0 };
        self.mostRecentRegion = MKCoordinateRegionMake(p, MKCoordinateSpanMake(0, 0));

        OBANavigationTarget *target = [OBASearch getNavigationTargetForSearchNone];
        [self.searchController searchWithTarget:target];
    }
    else {
        span.latitudeDelta  *= OBARegionScaleFactor;
        span.longitudeDelta *= OBARegionScaleFactor;
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

    [self.class setAnnotationsForMapView:self.mapView fromSearchResult:self.searchController.result bookmarkAnnotations:[self bookmarkAnnotations]];
    [self setOverlaysFromResults];
    [self setRegionFromResults];

    NSString *label = [self computeLabelForCurrentResults];
    [self applyMapLabelWithText:label];

    [self checkResults];

    if (self.doneLoadingMap && [OBAApplication sharedApplication].modelDao.currentRegion && [self outOfServiceArea]) {
        [self showOutOfRangeAlert];
    }
}

- (void)applyMapLabelWithText:(NSString *)labelText {
    self.mapLabel.text = labelText;

    if (labelText.length > 0 && self.mapLabelContainer.hidden) {
        self.mapLabelContainer.alpha = 0.f;
        self.mapLabelContainer.hidden = NO;

        [OBAAnimation performAnimations:^{
            self.mapLabelContainer.alpha = 1.f;
        }];
    }
    else if (labelText.length == 0) {
        [OBAAnimation performAnimations:^{
            self.mapLabelContainer.alpha = 0.f;
        } completion:^(BOOL finished) {
            self.mapLabelContainer.hidden = YES;
        }];
    }
}

- (CLLocation *)currentLocation {
    CLLocation *loc = self.searchController.searchLocation;
    if ([OBAApplication sharedApplication].locationManager.currentLocation) {
        return [OBAApplication sharedApplication].locationManager.currentLocation;
    }
    else if (loc) {
        return loc;
    }
    else {
        return [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude];
    }
}

- (void)showOutOfRangeAlert {
    if (self.hideFutureOutOfRangeErrors) {
        return;
    }

    NSString *regionName = [OBAApplication sharedApplication].modelDao.currentRegion.regionName;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"text_ask_go_to_region_param", @"Out of range alert title"), regionName]
                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"text_ask_go_to_service_area_param", @"Out of range alert message"), regionName]
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_no", @"Out of range alert Cancel button") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.hideFutureOutOfRangeErrors = YES;
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Out of Region Alert: NO" value:nil];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_yes", @"Out of range alert OK button") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Out of Region Alert: YES" value:nil];
        MKMapRect serviceRect = [[OBAApplication sharedApplication].modelDao.currentRegion serviceRect];
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

/* I feel like 2/3's of this method could be replaced
   by using an NSSet instead of an array. Something to
   consider going forward. */
+ (void)setAnnotationsForMapView:(MKMapView*)mapView fromSearchResult:(OBASearchResult*)result bookmarkAnnotations:(NSArray*)bookmarks {
    NSMutableArray *allCurrentAnnotations = [[NSMutableArray alloc] init];

    [allCurrentAnnotations addObjectsFromArray:bookmarks];

    NSSet *bookmarkStopIDs = [NSSet setWithArray:[bookmarks valueForKey:@"stopId"]];

    // prospectiveAnnotation *should* be an OBAStopV2, but there are some indications that this
    // is not always the case. To that end, we'll just go belt and suspenders on it and see if
    // the object responds to the appropriate selector. Additionally, I've added a type check
    // to validate my own assumptions about this.
    // https://github.com/OneBusAway/onebusaway-iphone/issues/825
    for (id prospectiveAnnotation in result.values) {
        OBAGuardClass(prospectiveAnnotation, OBAStopV2) else {
            DDLogError(@"prospectiveAnnotation is an instance of %@, and not OBAStopV2!", NSStringFromClass([prospectiveAnnotation class]));
        }

        if (![prospectiveAnnotation respondsToSelector:@selector(stopId)]) {
            continue;
        }

        NSString *stopID = [prospectiveAnnotation stopId];

        if ([bookmarkStopIDs containsObject:stopID]) {
            continue;
        }

        [allCurrentAnnotations addObject:prospectiveAnnotation];
    }

    NSMutableArray *toAdd = [[NSMutableArray alloc] init];
    NSMutableArray *toRemove = [[NSMutableArray alloc] init];

    for (id<MKAnnotation> installedAnnotation in mapView.annotations) {

        if ([installedAnnotation isKindOfClass:[MKUserLocation class]]) {
            continue;
        }

        if (![allCurrentAnnotations containsObject:installedAnnotation]) {
            [toRemove addObject:installedAnnotation];
        }
    }

    for (id annotation in allCurrentAnnotations) {
        if (![mapView.annotations containsObject:annotation]) {
            [toAdd addObject:annotation];
        }
    }

    DDLogInfo(@"Annotations to remove: %@", @(toRemove.count));
    DDLogInfo(@"Annotations to add: %@", @(toAdd.count));

    [mapView removeAnnotations:toRemove];
    [mapView addAnnotations:toAdd];
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

- (NSArray*)bookmarkAnnotations {
    NSArray *bookmarks = [OBAApplication sharedApplication].modelDao.bookmarksForCurrentRegion;

    NSArray *filtered = [bookmarks filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OBABookmarkV2* bookmark, NSDictionary *bindings) {
        return bookmark.stopId && CLLocationCoordinate2DIsValid(bookmark.coordinate) && bookmark.coordinate.latitude != 0 && bookmark.coordinate.longitude != 0;
    }]];

    return filtered;
}

- (NSString *)computeSearchFilterString {
    OBASearchType type = self.searchController.searchType;
    id param = self.searchController.searchParameter;

    switch (type) {
        case OBASearchTypeRoute:
            return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"msg_route", @"route"), param];

        case OBASearchTypeRouteStops: {
            OBARouteV2 *route = [[OBAApplication sharedApplication].references getRouteForId:param];

            if (route) return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"msg_route", @"route"), [route safeShortName]];

            return NSLocalizedString(@"msg_route", @"route");
        }

        case OBASearchTypeStopId:
            return [NSString stringWithFormat:@"%@ # %@", NSLocalizedString(@"msg_stop", @"OBASearchTypeStopId"), param];

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

    if (span.latitudeDelta > OBAMaxLatitudeDeltaToShowStops) {
        defaultLabel = NSLocalizedString(@"msg_zoom_on_map_for_look_stop", @"span.latitudeDelta > kMaxLatDeltaToShowStops");
    }

    if (!result) {
        return defaultLabel;
    }

    switch (result.searchType) {
        case OBASearchTypeRoute:
        case OBASearchTypeRouteStops:
        case OBASearchTypeAddress:
        case OBASearchTypeStopId:
            return nil;

        case OBASearchTypePlacemark:
        case OBASearchTypeRegion: {
            if (![self checkStopsInRegion] && span.latitudeDelta <= OBAMaxLatitudeDeltaToShowStops) {
                defaultLabel = NSLocalizedString(@"msg_no_stops_location_map", @"[values count] == 0");
            }

            break;
        }

        case OBASearchTypePending:
        case OBASearchTypeNone:
            break;
    }

    if ([OBAApplication sharedApplication].modelDao.currentRegion && [self outOfServiceArea]) {
        return NSLocalizedString(@"msg_out_oba_service_area", @"result.outOfRange");
    }

    return defaultLabel;
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

    OBASearchResult *result = self.searchController.result;

    if (!result || (result.values.count == 0 && result.additionalValues.count == 0)) {
        *needsUpdate = NO;
        return self.mapView.region;
    }

    switch (result.searchType) {
        case OBASearchTypeStopId:
            return [OBAMapHelpers computeRegionForNClosestStops:result.values center:[self currentLocation] numberOfStops:kShowNClosestStops];

        case OBASearchTypeRoute:
        case OBASearchTypeRouteStops:
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
    OBASearchResult *result = self.searchController.result;

    if (!result) return;

    switch (result.searchType) {
        case OBASearchTypeRegion:
        case OBASearchTypePlacemark: {
            [self checkOutOfRangeResults];
            break;
        }

        case OBASearchTypeRoute: {
            if (![self checkOutOfRangeResults]) {
                [self checkNoRouteResults];
            }

            break;
        }

        case OBASearchTypeAddress: {
            if (![self checkOutOfRangeResults]) {
                [self checkNoPlacemarksResults];
            }

            break;
        }

        case OBASearchTypeStopId: {
            if (![self checkOutOfRangeResults]) {
                [self checkNoStopIdResults];
            }

            break;
        }

        default:
            break;
    }
}

- (BOOL)checkOutOfRangeResults {
    if (self.searchController.result.outOfRange) {
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"msg_out_of_range", @"showNoResultsAlertWithTitle")
                                   prompt:NSLocalizedString(@"msg_explanatory_out_of_range", @"prompt")];
    }

    return self.searchController.result.outOfRange;
}

- (void)checkNoRouteResults {
    if (0 == self.searchController.result.values.count) {
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"msg_no_routes_found", @"showNoResultsAlertWithTitle")
                                   prompt:NSLocalizedString(@"msg_explanatory_no_routes_found", @"prompt")];
    }
}

- (void)checkNoStopIdResults {
    if (0 == self.searchController.result.values.count) {
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"msg_minus_no_stops_found", @"showNoResultsAlertWithTitle")
                                   prompt:NSLocalizedString(@"msg_explanatory_minus_no_stops_found", @"prompt")];
    }
}

- (void)checkNoPlacemarksResults {
    OBASearchResult *result = self.searchController.result;

    if ([result.values count] == 0) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self showNoResultsAlertWithTitle:NSLocalizedString(@"msg_no_places_found", @"showNoResultsAlertWithTitle") prompt:NSLocalizedString(@"msg_explanatory_no_places_found", @"prompt")];
    }
}

- (void)showNoResultsAlertWithTitle:(NSString *)title prompt:(NSString *)prompt {
    self.navigationItem.rightBarButtonItem.enabled = NO;

    if (!self.controllerIsVisibleAndActive) {
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:NSLocalizedString(@"msg_ask_go_selected_region",)
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_go_to_region",) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (self.modelDAO.currentRegion) {
            [self.mapView setRegion:MKCoordinateRegionForMapRect(self.modelDAO.currentRegion.serviceRect)];
        }
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)cancelPressed {
    self.navigationItem.title = kDefaultTitle;
    self.navigationItem.titleView = self.titleView;

    [self.searchController searchWithTarget:[OBASearch getNavigationTargetForSearchNone]];
    [self refreshStopsInRegion];
    self.navigationItem.rightBarButtonItem = self.listBarButtonItem;
}

- (BOOL)controllerIsVisibleAndActive {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        // Ignore errors if our view isn't currently on top
        return self == self.navigationController.visibleViewController;
    }
    else {
        // Ignore errors if our app isn't currently active
        return NO;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.searchBar.isFirstResponder) {
        [self searchBarCancelButtonClicked:self.searchBar];
    }
}

- (BOOL)outOfServiceArea {
    return [OBAMapHelpers visibleMapRect:self.mapView.visibleMapRect isOutOfServiceArea:[OBAApplication sharedApplication].modelDao.currentRegion.bounds];
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

#pragma mark - Private Configuration Junk

- (void)configureMapLabel {

    UIView *mapLabelParentView = nil;

    if ([OBATheme useHighContrastUI]) {
        UIView *container = [[OBAVibrantBlurContainerView alloc] initWithFrame:CGRectZero];
        container.backgroundColor = [UIColor darkGrayColor];
        self.mapLabelContainer = container;
        mapLabelParentView = container;
    }
    else {
        OBAVibrantBlurContainerView *container = [[OBAVibrantBlurContainerView alloc] initWithFrame:CGRectZero];
        container.blurEffectStyle = UIBlurEffectStyleDark;
        self.mapLabelContainer = container;
        mapLabelParentView = container.vibrancyEffectView.contentView;
    }

    self.mapLabelContainer.hidden = YES;
    self.mapLabelContainer.alpha = 0;
    self.mapLabelContainer.layer.cornerRadius = [OBATheme defaultCornerRadius];
    self.mapLabelContainer.layer.masksToBounds = YES;

    self.mapLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.mapLabel.textAlignment = NSTextAlignmentCenter;
    self.mapLabel.textColor = [OBATheme darkBlurLabelTextColor];
    self.mapLabel.font = [OBATheme boldBodyFont];

    [mapLabelParentView addSubview:self.mapLabel];
    [self.view addSubview:self.mapLabelContainer];

    [self.mapLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.mapLabelContainer).insets(UIEdgeInsetsMake([OBATheme compactPadding], [OBATheme defaultPadding], [OBATheme compactPadding], [OBATheme defaultPadding]));
    }];

    [self.mapLabelContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.mas_topLayoutGuideBottom).offset([OBATheme defaultPadding]);
    }];
}

- (void)setHighContrastStyle {
    [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryAccessibility action:@"increase_contrast" label:[NSString stringWithFormat:@"Loaded view: %@ with Increased Contrast", [self class]] value:nil];

    self.searchBar.barTintColor = [OBATheme OBADarkGreen];
    self.searchBar.tintColor = [UIColor whiteColor];

    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.navigationController.tabBarController.tabBar.barTintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];

    self.scopeView.backgroundColor = [UIColor blackColor];
    self.scopeView.tintColor = [OBATheme OBADarkGreen];
}

- (void)setRegularStyle {
    self.searchBar.barTintColor = nil;
    self.searchBar.tintColor = nil;

    self.navigationController.navigationBar.barTintColor = nil;
    self.navigationController.tabBarController.tabBar.barTintColor = nil;
    self.navigationController.navigationBar.tintColor = [OBATheme OBAGreen];

    self.scopeView.backgroundColor = [OBATheme OBAGreenWithAlpha:0.8f];
    self.scopeView.tintColor = nil;
}

- (MKUserTrackingBarButtonItem*)trackingBarButtonItem {
    if (!_trackingBarButtonItem) {
        _trackingBarButtonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    }
    return _trackingBarButtonItem;
}

@end
