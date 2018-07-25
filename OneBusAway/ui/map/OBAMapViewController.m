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
#import "OBAMapActivityIndicatorView.h"
#import "OneBusAway-Swift.h"
#import "SVPulsingAnnotationView.h"
#import "UIViewController+OBAContainment.h"
#import "UIViewController+OBAAdditions.h"
#import "OBAMapAnnotationViewBuilder.h"
#import "MKMapView+oba_Additions.h"
#import "ISHHoverBar.h"
#import "OBAToastView.h"
#import "OBAApplicationDelegate.h"
#import "OBAArrivalAndDepartureViewController.h"

static const NSUInteger kShowNClosestStops = 4;
static const double kStopsInRegionRefreshDelayOnDrag = 0.1;

@interface OBAMapViewController ()<MKMapViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, MapSearchDelegate, OBANavigator, OBAMapRegionDelegate, OBAEmbeddedStopDelegate, OBAVehicleDisambiguationDelegate>

// Map UI
@property(nonatomic,strong) MKMapView *mapView;
@property(nonatomic,strong) ISHHoverBar *locationHoverBar;
@property(nonatomic,strong) ISHHoverBar *secondaryHoverBar;
@property(nonatomic,strong) OBAToastView *toastView;
@property(nonatomic,strong) UIImageView *mapCenterImage;

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

- (instancetype)initWithMapDataLoader:(OBAMapDataLoader*)mapDataLoader mapRegionManager:(OBAMapRegionManager*)mapRegionManager {
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        _standaloneMode = YES;

        _mapDataLoader = mapDataLoader;
        [_mapDataLoader addDelegate:self];

        _mapRegionManager = mapRegionManager;
        [_mapRegionManager addDelegate:self];

        self.title = NSLocalizedString(@"msg_map", @"Map tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Map"];
        self.tabBarItem.selectedImage = [UIImage imageNamed:@"Map_Selected"];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userHeadingDidUpdate:) name:OBAHeadingDidUpdateNotification object:nil];

        [OBAApplication.sharedApplication.userDefaults addObserver:self forKeyPath:OBADisplayUserHeadingOnMapDefaultsKey options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self.mapDataLoader cancelOpenConnections];
    [OBAApplication.sharedApplication.userDefaults removeObserver:self forKeyPath:OBADisplayUserHeadingOnMapDefaultsKey];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == OBAApplication.sharedApplication.userDefaults && [keyPath isEqual:OBADisplayUserHeadingOnMapDefaultsKey]) {
        BOOL value = [OBAApplication.sharedApplication.userDefaults boolForKey:OBADisplayUserHeadingOnMapDefaultsKey];
        self.userLocationAnnotationView.headingImageView.hidden = !value;
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createMapView];

    [self configureMapActivityIndicator];

    self.mostRecentRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0));

    self.mapView.rotateEnabled = NO;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        self.mapView.showsUserLocation = YES;
    }

    if (self.standaloneMode) {
        [self createLocationHoverBar];
        [self createSecondaryHoverBar];
        [self configureSearch];
    }

    self.hideFutureNetworkErrors = NO;

    if ([OBATheme useHighContrastUI]) {
        [self setHighContrastStyle];
    }
    else {
        [self setRegularStyle];
    }

    [self configureToastView];

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

#pragma mark - Drawer UI

- (BOOL)usingDrawerUI {
    return [OBAApplication.sharedApplication.userDefaults boolForKey:OBAExperimentalUseDrawerUIDefaultsKey];
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
        self.mapDataLoader.searchRegion = self.visibleMapRegion;
        [self setNavigationTarget:target];
    }];
}

- (CLCircularRegion*)visibleMapRegion {
    return [OBAMapHelpers convertVisibleMapRect:self.mapView.visibleMapRect intoCircularRegionWithCenter:self.mapView.centerCoordinate];
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

- (PromisedModelService*)modelService {
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

#pragma mark - OBANavigationTargetAware

- (void)setNavigationTarget:(OBANavigationTarget *)target {
    if (OBASearchTypeRegion == target.searchType) {
        [self.mapDataLoader searchPending];
        [self.mapRegionManager setRegionFromNavigationTarget:target];
    }
    else if (OBASearchTypeStopId == target.searchType) {
        [self displayStopControllerForStopID:target.searchArgument];
    }
    else if ([target isKindOfClass:OBAVehicleIDNavigationTarget.class]) {
        [SVProgressHUD show];
        OBAVehicleIDNavigationTarget *vehicleNavTarget = (OBAVehicleIDNavigationTarget*)target;
        PromiseWrapper *wrapper = [self.modelService requestVehiclesMatching:vehicleNavTarget.query in:self.modelDAO.currentRegion];
        wrapper.anyPromise.then(^(NetworkResponse *response) {
            NSArray<OBAMatchingAgencyVehicle*> *matchingVehicles = response.object;

            if (matchingVehicles.count == 1) {
                return [self.modelService requestVehicleTrip:matchingVehicles.firstObject.vehicleID].anyPromise;
            }
            else {
                // pop up a disambiguation UI.
                [self disambiguateMatchingVehicles:matchingVehicles];
                return [AnyPromise promiseWithValue:nil];
            }
        }).then(^(NetworkResponse *response) {
            if (response) {
                OBATripDetailsV2 *tripDetails = (OBATripDetailsV2 *)response.object;
                OBAArrivalAndDepartureViewController *controller = [[OBAArrivalAndDepartureViewController alloc] initWithTripInstance:tripDetails.tripInstance];
                [self.navigationController pushViewController:controller animated:YES];
            }
        }).catch(^(NSError *error) {
            [AlertPresenter showError:error presentingController:self];
        }).always(^{
            [SVProgressHUD dismiss];
        });
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

        [AlertPresenter showError:error presentingController:self];
    }
}

- (void)mapDataLoader:(OBAMapDataLoader*)mapDataLoader startedUpdatingWithNavigationTarget:(OBANavigationTarget*)target {
    [self.mapActivityIndicatorView setAnimating:YES];
}

- (void)mapDataLoaderFinishedUpdating:(OBAMapDataLoader*)searchController {
    [self.mapActivityIndicatorView setAnimating:NO];
}

#pragma mark - OBAMapRegionDelegate

- (void)mapRegionManager:(OBAMapRegionManager*)manager setRegion:(MKCoordinateRegion)region animated:(BOOL)animated {
    [self.mapView setRegion:region animated:animated];
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
        [annotationView.superview sendSubviewToBack:annotationView];
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
}

- (void)userHeadingDidUpdate:(NSNotification*)note {
    if (!self.userLocationAnnotationView) {
        return;
    }

    CLHeading *heading = note.userInfo[OBAHeadingUserInfoKey];
    [self updateUserLocationAnnotationViewWithHeading:heading];
}

- (void)updateUserLocationAnnotationViewWithHeading:(CLHeading*)heading {
    _userLocationAnnotationView.headingImageView.hidden = ![OBAApplication.sharedApplication.userDefaults boolForKey:OBADisplayUserHeadingOnMapDefaultsKey];
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
        _userLocationAnnotationView.userInteractionEnabled = NO;
    }

    BOOL showHeading = [OBAApplication.sharedApplication.userDefaults boolForKey:OBADisplayUserHeadingOnMapDefaultsKey];

    if (heading && showHeading) {
        [self updateUserLocationAnnotationViewWithHeading:heading];
    }
    else {
        _userLocationAnnotationView.headingImageView.hidden = YES;
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:MKUserLocation.class]) {
        [self buildUserLocationAnnotationViewForAnnotation:annotation heading:self.locationManager.currentHeading];
        return self.userLocationAnnotationView;
    }
    else if ([annotation isKindOfClass:OBAStopV2.class] || [annotation isKindOfClass:OBABookmarkV2.class]) {
        return [OBAMapAnnotationViewBuilder viewForAnnotation:annotation forMapView:mapView];
    }
    else if ([annotation isKindOfClass:OBAPlacemark.class]) {
        return [OBAMapAnnotationViewBuilder mapView:mapView viewForPlacemark:(OBAPlacemark*)annotation withSearchType:self.mapDataLoader.result.searchType];
    }
    else if ([annotation isKindOfClass:OBANavigationTargetAnnotation.class]) {
        return [OBAMapAnnotationViewBuilder mapView:mapView viewForNavigationTarget:annotation];
    }

    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    [mapView deselectAnnotation:view.annotation animated:YES];

    OBAStopV2 *stop = nil;

    if ([view.annotation isKindOfClass:OBABookmarkV2.class]) {
        stop = ((OBABookmarkV2*)view.annotation).stop;
    }
    else if ([view.annotation isKindOfClass:OBAStopV2.class]) {
        stop = (OBAStopV2*)view.annotation;
    }
    else {
        return;
    }

    OBAStopViewController *stopController = [[OBAStopViewController alloc] initWithStopID:stop.stopId];
    stopController.embedDelegate = self;
    stopController.inEmbedMode = YES;

    [self oba_presentPopoverViewController:stopController fromView:view popoverSize:CGSizeMake(OBATheme.preferredPopoverWidth, 225) hideNavigationBar:NO];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    id annotation = view.annotation;

    if ([annotation isKindOfClass:[OBAPlacemark class]]) {
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

#pragma mark OBAEmbeddedStopDelegate

- (void)embeddedStopController:(OBAStopViewController*)stopController showStop:(NSString*)stopID {
    [stopController.presentingViewController dismissViewControllerAnimated:NO completion:^{
        [self displayStopControllerForStopID:stopID];
    }];
}

- (void)embeddedStopController:(OBAStopViewController*)stopController pushViewController:(UIViewController*)viewController animated:(BOOL)animated {
    [stopController.presentingViewController dismissViewControllerAnimated:NO completion:^{
        [self.navigationController pushViewController:viewController animated:YES];
    }];
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
- (IBAction)changeMapTypes:(UIButton*)sender {
    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil];

    OBATableRow *standardRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"map_controller.standard_map_type_title", @"Title for Standard Map toggle option.") action:^(OBABaseRow *row) {
        self.mapView.mapType = MKMapTypeStandard;
        [OBAApplication.sharedApplication.userDefaults setInteger:MKMapTypeStandard forKey:OBAMapSelectedTypeDefaultsKey];
    }];

    OBATableRow *hybridRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"map_controller.hybrid_map_type_title", @"Title for Hybrid Map toggle option.") action:^(OBABaseRow *row) {
        self.mapView.mapType = MKMapTypeHybrid;
        [OBAApplication.sharedApplication.userDefaults setInteger:MKMapTypeHybrid forKey:OBAMapSelectedTypeDefaultsKey];
    }];

    if (self.mapView.mapType == MKMapTypeStandard) {
        standardRow.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else if (self.mapView.mapType == MKMapTypeHybrid) {
        hybridRow.accessoryType = UITableViewCellAccessoryCheckmark;
    }

    [section addRow:standardRow];
    [section addRow:hybridRow];

    PickerViewController *picker = [[PickerViewController alloc] init];
    picker.sections = @[section];

    [self oba_presentPopoverViewController:picker fromView:sender];
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

- (void)showSearchDisambiguatorWithSearchResult:(OBASearchResult*)searchResult {
    NearbyStopsViewController *nearbyStops = [[NearbyStopsViewController alloc] initWithSearchResult:searchResult];
    nearbyStops.title = NSLocalizedString(@"nearby_stops.disambiguation_title", @"Title of the the Nearby Stops controller when it's in disambiguation mode. In English, this is just the word 'Disambiguate'.");
    nearbyStops.closeButtonTitle = OBAStrings.cancel;
    [nearbyStops setCanceled:^{
        [self cancelCurrentSearch];
    }];
    nearbyStops.presentedModally = YES;
    nearbyStops.navigator = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:nearbyStops];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showNearbyStopsWithSearchResult:(OBASearchResult*)searchResult {
    NearbyStopsViewController *nearbyStops = [[NearbyStopsViewController alloc] initWithSearchResult:searchResult];
    nearbyStops.presentedModally = YES;
    nearbyStops.navigator = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:nearbyStops];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)navigateToTarget:(OBANavigationTarget*)navigationTarget {
    if (navigationTarget.searchType == OBASearchTypeStopId) {
        [self displayStopControllerForStopID:navigationTarget.searchArgument];
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
    [self displayStopControllerForStopID:stop.stopId];
}

- (void)displayStopControllerForStopID:(NSString*)stopID {
    OBAStopViewController *stopController = [[OBAStopViewController alloc] initWithStopID:stopID];
    [self.navigationController pushViewController:stopController animated:YES];
}

#pragma mark - OBAMapViewController Private Methods

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

    if (result && result.searchType == OBASearchTypeRoute && result.values.count > 0) {
        if (result.values.count == 1) {
            // short-circuit and show the result.
            OBARouteV2 *route = result.values[0];
            OBANavigationTarget *target = [OBANavigationTarget navigationTargetForRoute:route];
            [self setNavigationTarget:target];
        }
        else {
            [self showSearchDisambiguatorWithSearchResult:result];
        }
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
        case OBASearchTypeStopId:
        case OBASearchTypeStopIdSearch: {
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

        case OBASearchTypeRegionalAlert:
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
        case OBASearchTypeStopIdSearch:
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
    else if (OBASearchTypeStopId == result.searchType || OBASearchTypeStopIdSearch == result.searchType) {
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

#pragma mark - Vehicle Search

- (void)disambiguateMatchingVehicles:(NSArray<OBAMatchingAgencyVehicle*>*)matchingVehicles {
    OBAVehicleDisambiguationViewController *d = [[OBAVehicleDisambiguationViewController alloc] initWithMatchingVehicles:matchingVehicles delegate:self];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:d];

    [self presentViewController:nav animated:YES completion:nil];
}

- (void)disambiguator:(OBAVehicleDisambiguationViewController *)viewController didSelect:(OBAMatchingAgencyVehicle *)matchingVehicle {
    [viewController dismissViewControllerAnimated:YES completion:^{
        [SVProgressHUD show];

        // abxoxo - todo - add this wrapper to a 'disposal bag' or something that can be cancelled
        // if the user exits this view controller before this operation finishes.
        PromiseWrapper *wrapper = [self.modelService requestVehicleTrip:matchingVehicle.vehicleID];
        wrapper.anyPromise.then(^(NetworkResponse *response){
            OBATripDetailsV2 *tripDetails = (OBATripDetailsV2 *)response.object;
            OBAArrivalAndDepartureViewController *controller = [[OBAArrivalAndDepartureViewController alloc] initWithTripInstance:tripDetails.tripInstance];
            [self.navigationController pushViewController:controller animated:YES];
        }).catch(^(NSError *error) {
            [AlertPresenter showError:error presentingController:self];
        }).always(^{
            [SVProgressHUD dismiss];
        });
    }];
}

#pragma mark - UI Configuration

- (void)createMapView {
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.mapView.delegate = self;
    self.mapView.mapType = [OBAApplication.sharedApplication.userDefaults integerForKey:OBAMapSelectedTypeDefaultsKey];
    [self.view addSubview:self.mapView];

    if (self.usingDrawerUI) {
        self.mapCenterImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_center"]];
        self.mapCenterImage.alpha = 0.3f;
        [self.view addSubview:self.mapCenterImage];
        [self.mapCenterImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.mapView);
        }];
    }
}

- (void)configureMapActivityIndicator {
    self.mapActivityIndicatorView = [[OBAMapActivityIndicatorView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.mapActivityIndicatorView];
    [self.mapActivityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuideBottom).offset(OBATheme.defaultPadding);
        make.leading.equalTo(self).offset(OBATheme.defaultMargin);
    }];
}

- (void)configureToastView {
    self.toastView = [[OBAToastView alloc] initWithFrame:CGRectZero];
    [self.toastView.button addTarget:self action:@selector(cancelCurrentSearch) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toastView];

    [self.toastView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.mas_topLayoutGuideBottom).offset(OBATheme.defaultPadding);
        make.width.lessThanOrEqualTo(self.view);
    }];
}

- (void)createLocationHoverBar {
    UIBarButtonItem *recenterMapButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Map_Selected"] landscapeImagePhone:nil style:UIBarButtonItemStylePlain target:self action:@selector(recenterMap)];

    self.locationHoverBar = [[ISHHoverBar alloc] init];
    self.locationHoverBar.items = @[recenterMapButton];
    [self.view addSubview:self.locationHoverBar];
    [self.locationHoverBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.mas_bottomLayoutGuideTop).offset(-OBATheme.defaultMargin);
        make.trailing.equalTo(self).offset(-OBATheme.defaultMargin);
    }];
}

- (void)createSecondaryHoverBar {
    self.secondaryHoverBar = [[ISHHoverBar alloc] init];

    UIBarButtonItem *nearbyButton = [OBAUIBuilder wrappedImageButton:[UIImage imageNamed:@"map_signs"] accessibilityLabel:NSLocalizedString(@"msg_nearby_stops_list", @"self.listBarButtonItem.accessibilityLabel") target:self action:@selector(showNearbyStops)];

    NSString *label = NSLocalizedString(@"map_controller.toggle_map_type_accessibility_label", @"Accessibility label for toggle map type button on map.");
    UIBarButtonItem *mapBarButton = [OBAUIBuilder wrappedImageButton:[UIImage imageNamed:@"map_button"] accessibilityLabel:label target:self action:@selector(changeMapTypes:)];

    self.secondaryHoverBar.items = @[nearbyButton, mapBarButton];

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
