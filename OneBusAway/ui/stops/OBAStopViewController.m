//
//  OBAStopViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/20/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAStopViewController.h"
@import OBAKit;
@import PromiseKit;
@import PMKCoreLocation;
@import PMKMapKit;
@import SVProgressHUD;
#import "OneBusAway-Swift.h"
#import "OBASeparatorSectionView.h"
#import "OBAReportProblemWithRecentTripsViewController.h"
#import "OBAEditStopPreferencesViewController.h"
#import "OBAStopTableHeaderView.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBAAnalytics.h"
#import "OBALabelFooterView.h"
#import "OBASegmentedRow.h"
#import "OBAArrivalAndDepartureViewController.h"
#import "OBAStaticTableViewController+Builders.h"
#import "OBABookmarkRouteDisambiguationViewController.h"
#import "OBAWalkableRow.h"
#import "OBAPushManager.h"
#import "OBAArrivalDepartureOptionsSheet.h"
#import "UIViewController+OBAAdditions.h"
#import "EXTScope.h"

static NSTimeInterval const kRefreshTimeInterval = 30.0;
static CGFloat const kTableHeaderHeight = 150.f;
static NSInteger kStopsSectionTag = 101;
static NSInteger kNegligibleWalkingTimeToStop = 25;

@interface OBAStopViewController ()<UIScrollViewDelegate, UIActivityItemSource, OBAArrivalDepartureOptionsSheetDelegate>
@property(nonatomic,strong) UIRefreshControl *refreshControl;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) NSLock *reloadLock;
@property(nonatomic,strong) OBAArrivalsAndDeparturesForStopV2 *arrivalsAndDepartures;
@property(nonatomic,strong) OBAStopPreferencesV2 *stopPreferences;
@property(nonatomic,strong) OBARouteFilter *routeFilter;
@property(nonatomic,strong) OBAStopTableHeaderView *stopHeaderView;
@property(nonatomic,strong) OBAArrivalDepartureOptionsSheet *departureSheetHelper;
@end

@implementation OBAStopViewController

- (instancetype)initWithStopID:(NSString*)stopID {
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        _reloadLock = [[NSLock alloc] init];
        _stopID = [stopID copy];
        _minutesBefore = 5;
        _minutesAfter = 35;
    }
    return self;
}

- (void)dealloc {
    [self cancelTimers];
}

- (void)cancelTimers {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"stop_view_controller.stop_back_title", @"Back button title representing going back to the stop controller.");

    [self createTableHeaderView];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadData:)];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    OBALogFunction();

    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval target:self selector:@selector(reloadData:) userInfo:nil repeats:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    [self populateTableFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    [self reloadDataAnimated:NO];
    
    [[OBAHandoff shared] broadcastWithStopID:self.stopID withRegion:self.modelDAO.currentRegion];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // Nil these out to ensure that they are recreated once the
    // view comes back into focus, which is important if the user
    // has exited this view to go to the filter & sort view controller.
    self.routeFilter = nil;
    self.stopPreferences = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];

    [self cancelTimers];
    
    [[OBAHandoff shared] stopBroadcasting];
}

#pragma mark - Notifications

- (void)willEnterForeground:(NSNotification*)note {

    // First, reload the table so that times adjust properly.
    [self.tableView reloadData];

    // And then reload remote data.
    [self reloadData:nil];
}

#pragma mark - Accessors

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (PromisedModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

- (OBAStopPreferencesV2*)stopPreferences {
    if (!_stopPreferences) {
        _stopPreferences = [self.modelDAO stopPreferencesForStopWithId:self.stopID];
    }
    return _stopPreferences;
}

- (OBARouteFilter*)routeFilter {
    if (!_routeFilter) {
        _routeFilter = [[OBARouteFilter alloc] initWithStopPreferences:self.stopPreferences];
    }
    return _routeFilter;
}

- (OBALocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager = [OBAApplication sharedApplication].locationManager;
    }
    return _locationManager;
}

- (OBAArrivalDepartureOptionsSheet*)departureSheetHelper {
    if (!_departureSheetHelper) {
        _departureSheetHelper = [[OBAArrivalDepartureOptionsSheet alloc] initWithDelegate:self];
    }

    return _departureSheetHelper;
}

#pragma mark - Data Loading

- (void)reloadData:(id)sender {
    BOOL animated = ![sender isEqual:self.navigationItem.rightBarButtonItem];
    [self reloadDataAnimated:animated];
}

- (void)reloadDataAnimated:(BOOL)animated {
    // If we're already loading data, then just bail.
    if (![self.reloadLock tryLock]) {
        return;
    }

    if (animated) {
        [self.refreshControl beginRefreshing];
    }

    self.navigationItem.title = NSLocalizedString(@"stops_controller.title.updating", @"Title of the Stop UI Controller while it is updating its content.");

    [self.modelService promiseStopWithID:self.stopID minutesBefore:self.minutesBefore minutesAfter:self.minutesAfter].then(^(OBAArrivalsAndDeparturesForStopV2 *response) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"msg_updated", @"message"), [OBADateHelpers formatShortTimeNoDate:[NSDate date]]];
        [self.modelDAO viewedArrivalsAndDeparturesForStop:response.stop];

        self.arrivalsAndDepartures = response;

        [self populateTableFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
        [self.stopHeaderView populateTableHeaderFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    }).catch(^(NSError *error) {
        [AlertPresenter showError:error];
        DDLogError(@"An error occurred while displaying a stop: %@", error);
        return error;
    }).always(^{
        if (animated) {
            [self.refreshControl endRefreshing];
        }
        [self.reloadLock unlock];
    });
}

- (void)populateTableFromArrivalsAndDeparturesModel:(OBAArrivalsAndDeparturesForStopV2 *)result {
    if (!result) {
        return;
    }

    NSMutableArray *sections = [NSMutableArray array];

    // Toggle showing/hiding filtered routes.
    if ([self.routeFilter hasFilteredRoutes]) {
        [sections addObject:[self createToggleDepartureFilterSection]];
    }

    // Service Alerts
    OBAServiceAlertsModel *serviceAlerts = [self.modelDAO getServiceAlertsModelForSituations:result.situations];
    if (serviceAlerts.totalCount > 0) {
        [sections addObject:[self createServiceAlertsSection:result serviceAlerts:serviceAlerts]];
    }

    // Departures
    // TODO: DRY up this whole thing.
    if (self.stopPreferences.sortTripsByType == OBASortTripsByDepartureTimeV2) {
        OBATableSection *section = [self buildClassicDepartureSectionWithDeparture:result];
        [sections addObject:section];
    }
    else {
        NSDictionary *groupedArrivals = [OBAStopViewController groupPredictedArrivalsOnRoute:result.arrivalsAndDepartures];
        NSArray *arrivalKeys = [groupedArrivals.allKeys sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
        for (NSString *key in arrivalKeys) {
            NSArray<OBAArrivalAndDepartureV2*> *departures = groupedArrivals[key];

            // Exclude table sections for routes that the user has disabled and routes without departures.
            if (departures.count > 0 && [self.routeFilter shouldShowRouteID:departures[0].routeId]) {
                [sections addObject:[self createDepartureSectionWithTitle:key fromDepartures:departures]];
            }
        }
    }

    // "Load More Departures..."
    OBATableSection *loadMoreSection = [self createLoadMoreDeparturesSection];
    if (result.lacksRealTimeData) {
        OBATableRow *scheduledExplanationRow = [[OBATableRow alloc] initWithTitle:[OBAStrings scheduledDepartureExplanation] action:nil];
        scheduledExplanationRow.textAlignment = NSTextAlignmentCenter;
        scheduledExplanationRow.titleFont = [OBATheme italicFootnoteFont];
        scheduledExplanationRow.selectionStyle = UITableViewCellSelectionStyleNone;
        [loadMoreSection addRow:scheduledExplanationRow];
    }
    [sections addObject:loadMoreSection];

    self.sections = sections;
    [self.tableView reloadData];
}

#pragma mark - Walking

+ (NSArray<OBABaseRow*>*)insertWalkableRowIntoRows:(NSArray<OBABaseRow*>*)rows forCurrentLocation:(CLLocation*)location {
    NSUInteger insertionIndex = NSNotFound;

    OBAArrivalAndDepartureV2 *departure = nil;
    OBAStopV2 *stop = nil;
    NSTimeInterval walkingTime = 0;

    for (NSUInteger i=0; i<rows.count; i++) {
        if (![rows[i].model isKindOfClass:[OBAArrivalAndDepartureV2 class]]) {
            continue;
        }

        departure = rows[i].model;
        stop = departure.stop;
        walkingTime = [OBAWalkingDirections walkingTravelTimeFromLocation:location toLocation:stop.location];
        // Is walking time less than time until bus departs or is user already at bus stop and bus hasn't left yet?
        if ((departure.timeIntervalUntilBestDeparture > walkingTime) || (walkingTime < kNegligibleWalkingTimeToStop && departure.minutesUntilBestDeparture >= 0)) {
            insertionIndex = i;
            break;
        }
    }

    if (insertionIndex == NSNotFound) {
        return rows;
    }

    NSString *distanceString = [OBAMapHelpers stringFromDistance:[location distanceFromLocation:stop.location]];
    NSDate *expectedArrivalDate = [NSDate dateWithTimeIntervalSinceNow:walkingTime];

    OBAWalkableRow *walkableRow = [[OBAWalkableRow alloc] init];
    walkableRow.text = [NSString stringWithFormat:NSLocalizedString(@"text_walk_to_stop_info_params",), distanceString,expectedArrivalDate.minutesUntil,[OBADateHelpers formatShortTimeNoDate:expectedArrivalDate]];

    NSMutableArray<OBABaseRow*> *mRows = [[NSMutableArray alloc] initWithArray:rows];
    [mRows insertObject:walkableRow atIndex:insertionIndex];

    return [NSArray arrayWithArray:mRows];
}

#pragma mark - Table View Hacks

// This is used to hide the table view separator underneath an OBAWalkableRow, so
// that an effect like what is seen in the mockup in the following issue can be
// properly displayed: https://github.com/OneBusAway/onebusaway-iphone/issues/829
- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    OBABaseRow *row = [self rowAtIndexPath:indexPath];
    OBABaseRow *nextRow = [self rowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section]];
    CGRect bounds = tableView.bounds;

    if ([row isKindOfClass:[OBAWalkableRow class]] || [nextRow isKindOfClass:[OBAWalkableRow class]]) {
        cell.separatorInset = UIEdgeInsetsMake(0, CGRectGetWidth(bounds)/2.f, 0, CGRectGetWidth(bounds)/2.f);
    }
}

#pragma mark - Table Section Creation

- (OBATableSection *)buildClassicDepartureSectionWithDeparture:(OBAArrivalsAndDeparturesForStopV2 *)result {
    NSMutableArray *departureRows = [NSMutableArray array];

    NSArray<OBAArrivalAndDepartureV2*> *arrivalsAndDepartures = [result.arrivalsAndDepartures sortedArrayUsingComparator:^NSComparisonResult(OBAArrivalAndDepartureV2* obj1, OBAArrivalAndDepartureV2* obj2) {

        if (obj1.minutesUntilBestDeparture != obj2.minutesUntilBestDeparture) {
            return [obj1.bestArrivalDepartureDate compare:obj2.bestArrivalDepartureDate];
        }

        if (obj1.arrivalDepartureState == obj2.arrivalDepartureState) {
            return NSOrderedSame;
        }

        if (obj1.arrivalDepartureState == OBAArrivalDepartureStateArriving) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedDescending;
        }
    }];

    for (OBAArrivalAndDepartureV2 *dep in arrivalsAndDepartures) {
        if (![self.routeFilter shouldShowRouteID:dep.routeId]) {
            continue;
        }

        OBADepartureRow *row = [self buildDepartureRowForArrivalAndDeparture:dep];
        [departureRows addObject:row];
    }

    NSArray *rows = nil;

    CLLocation *location = self.locationManager.currentLocation;
    if (location) {
        rows = [OBAStopViewController insertWalkableRowIntoRows:departureRows forCurrentLocation:location];
    }
    else {
        rows = departureRows;
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:rows];
    section.tag = kStopsSectionTag;
    
    return section;
}

- (OBATableSection*)createToggleDepartureFilterSection {
    OBASegmentedRow *segmentedRow = [[OBASegmentedRow alloc] initWithSelectionChange:^(NSUInteger selectedIndex) {
        self.routeFilter.showFilteredRoutes = !self.routeFilter.showFilteredRoutes;
        [self populateTableFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    }];
    segmentedRow.items = @[NSLocalizedString(@"msg_all_departures", @""), NSLocalizedString(@"msg_filtered_departures", @"")];

    segmentedRow.selectedItemIndex = self.routeFilter.showFilteredRoutes ? 0 : 1;

    return [[OBATableSection alloc] initWithTitle:nil rows:@[segmentedRow]];
}

- (OBATableSection*)createLoadMoreDeparturesSection {
    OBATableRow *moreDeparturesRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_load_more_departures_dots", @"") action:^(OBABaseRow *r2) {
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked load more arrivals button" value:nil];
        self.minutesAfter += 30;
        [self reloadDataAnimated:NO];
    }];
    moreDeparturesRow.textAlignment = NSTextAlignmentCenter;
    return [[OBATableSection alloc] initWithTitle:nil rows:@[moreDeparturesRow]];
}

/**
 This method is used to build grouped sections for routes. i.e. go to "Sort & Filter Routes"
 and choose "Sort by Route".
 */
- (OBATableSection*)createDepartureSectionWithTitle:(NSString*)title fromDepartures:(NSArray<OBAArrivalAndDepartureV2*>*)departures {
    NSMutableArray *departureRows = [[NSMutableArray alloc] init];

    for (OBAArrivalAndDepartureV2* dep in departures) {
        OBADepartureRow *row = [self buildDepartureRowForArrivalAndDeparture:dep];
        [departureRows addObject:row];
    }

    NSArray *rows = nil;
    CLLocation *location = self.locationManager.currentLocation;
    if (location) {
        rows = [OBAStopViewController insertWalkableRowIntoRows:departureRows forCurrentLocation:location];
    }
    else {
        rows = departureRows;
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:title rows:rows];
    section.tag = kStopsSectionTag;
    return section;
}

- (OBADepartureRow*)buildDepartureRowForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    OBAArrivalAndDepartureSectionBuilder *builder = [[OBAArrivalAndDepartureSectionBuilder alloc] initWithModelDAO:self.modelDAO];
    OBADepartureRow *row = [builder createDepartureRowForStop:dep];

    [row setAction:^(OBABaseRow *blockRow){
        OBAArrivalAndDepartureViewController *vc = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDeparture:dep];
        [self.navigationController pushViewController:vc animated:YES];
    }];

    @weakify(row);
    [row setShowAlertController:^(UIView *presentingView) {
        @strongify(row);
        [self.departureSheetHelper showActionMenuForDepartureRow:row fromPresentingView:presentingView];
    }];

    return row;
}

#pragma mark - OBADepartureSheetDelegate

- (void)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet presentViewController:(UIViewController*)viewController fromView:(nullable UIView*)presentingView {
    [self.tableView setEditing:NO animated:YES];
    [self oba_presentViewController:viewController fromView:presentingView];
}

- (void)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet addedAlarm:(OBAAlarm*)alarm forArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalDeparture {
    NSIndexPath *indexPath = [self indexPathForModel:arrivalDeparture];
    OBADepartureRow *row = (OBADepartureRow *)[self rowAtIndexPath:indexPath];
    row.alarmExists = YES;
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet deletedAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    NSIndexPath *indexPath = [self indexPathForModel:arrivalAndDeparture];
    OBADepartureRow *row = (OBADepartureRow *)[self rowAtIndexPath:indexPath];
    row.alarmExists = NO;
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (UIView*)optionsSheetPresentationView:(OBAArrivalDepartureOptionsSheet*)optionsSheet {
    return self.view;
}

- (UIView*)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet viewForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    NSIndexPath *indexPath = [self indexPathForModel:arrivalAndDeparture];
    return [self.tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - UIActivityItemSource methods

// Make it possible to copy just the URL for trip sharing
// See bug #928
- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
    if (![activityType isEqualToString:UIActivityTypeCopyToPasteboard]) {
        return [NSString stringWithFormat:NSLocalizedString(@"text_follow_my_trip_param", @"Sharing link activity item in the stop view controller"), @""];
    }
    return nil;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
    return @"";
}

#pragma mark - Table Header

- (void)showFilterAndSortUI {
    OBAEditStopPreferencesViewController *vc = [[OBAEditStopPreferencesViewController alloc] initWithModelDAO:self.modelDAO stop:self.arrivalsAndDepartures.stop];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)showActionsMenu:(id)sender {
    OBAStopV2 *stop = self.arrivalsAndDepartures.stop;

    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    // Add Bookmark
    UIAlertAction *addBookmark = [UIAlertAction actionWithTitle:NSLocalizedString(@"msg_add_bookmark", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OBABookmarkRouteDisambiguationViewController *disambiguator = [[OBABookmarkRouteDisambiguationViewController alloc] initWithArrivalsAndDeparturesForStop:self.arrivalsAndDepartures];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:disambiguator];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    [actionSheet addAction:addBookmark];

    // Nearby Stops
    UIAlertAction *nearbyStops = [UIAlertAction actionWithTitle:NSLocalizedString(@"msg_nearby_stops", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NearbyStopsViewController *nearby = [[NearbyStopsViewController alloc] initWithStop:stop];
        nearby.pushesResultsOntoStack = YES;
        [self.navigationController pushViewController:nearby animated:YES];
    }];
    [actionSheet addAction:nearbyStops];

    // Walking Directions (Apple Maps)
    NSURL *appleMapsURL = [AppInterop appleMapsWalkingDirectionsURLWithCoordinate:stop.coordinate];
    UIAlertAction *walkingDirectionsApple = [UIAlertAction actionWithTitle:NSLocalizedString(@"stop.walking_directions_apple_action_title", @"Title of the 'Get Walking Directions (Apple Maps)' option in the action sheet.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [UIApplication.sharedApplication openURL:appleMapsURL options:@{} completionHandler:nil];
    }];
    [actionSheet addAction:walkingDirectionsApple];

    // Walking Directions (Google Maps)

    NSURL *googleMapsURL = [AppInterop googleMapsWalkingDirectionsURLWithCoordinate:stop.coordinate];
    if ([UIApplication.sharedApplication canOpenURL:googleMapsURL]) {
        UIAlertAction *walkingDirections = [UIAlertAction actionWithTitle:NSLocalizedString(@"stop.walking_directions_google_action_title", @"Title of the 'Get Walking Directions (Google Maps)' option in the action sheet.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [UIApplication.sharedApplication openURL:googleMapsURL options:@{} completionHandler:nil];
        }];
        [actionSheet addAction:walkingDirections];
    }

    // Report a Problem
    UIAlertAction *problem = [UIAlertAction actionWithTitle:NSLocalizedString(@"msg_report_a_problem", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OBAReportProblemWithRecentTripsViewController * vc = [[OBAReportProblemWithRecentTripsViewController alloc] initWithStopID:self.arrivalsAndDepartures.stop.stopId];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    [actionSheet addAction:problem];

    // Cancel
    [actionSheet addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];

    [self oba_presentViewController:actionSheet fromView:sender];
}

- (void)createTableHeaderView {
    self.stopHeaderView = [[OBAStopTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), kTableHeaderHeight)];
    self.stopHeaderView.highContrastMode = [OBATheme useHighContrastUI];

    [self.stopHeaderView.menuButton addTarget:self action:@selector(showActionsMenu:) forControlEvents:UIControlEventTouchUpInside];
    [self.stopHeaderView.filterButton addTarget:self action:@selector(showFilterAndSortUI) forControlEvents:UIControlEventTouchUpInside];

    self.tableView.tableHeaderView = self.stopHeaderView;
}

#pragma mark - Miscellaneous UI and Utilities

+ (NSDictionary*)groupPredictedArrivalsOnRoute:(NSArray<OBAArrivalAndDepartureV2*> *)predictedArrivals {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    for (OBAArrivalAndDepartureV2 *dep in predictedArrivals) {
        NSMutableArray *departures = dict[dep.bestAvailableName];

        if (!departures) {
            departures = [[NSMutableArray alloc] init];
            dict[dep.bestAvailableName] = departures;
        }

        [departures addObject:dep];
    }

    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
