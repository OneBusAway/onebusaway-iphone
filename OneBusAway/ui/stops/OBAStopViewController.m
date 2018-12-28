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
@import SVProgressHUD;
#import "OneBusAway-Swift.h"
#import "OBASeparatorSectionView.h"
#import "OBAReportProblemWithRecentTripsViewController.h"
#import "OBAEditStopPreferencesViewController.h"
#import "OBAStopTableHeaderView.h"
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
#import "OBANavigationTitleView.h"

@import Masonry;

static NSTimeInterval const kRefreshTimeInterval = 30.0;
static CGFloat const kTableHeaderHeight = 150.f;
static NSInteger kStopsSectionTag = 101;
static NSInteger kNegligibleWalkingTimeToStop = 25;

static NSUInteger const kDefaultMinutesBefore = 5;
static NSUInteger const kDefaultMinutesAfter = 35;

static void * arrivalsAndDeparturesContext = &arrivalsAndDeparturesContext;

@interface OBAStopViewController ()<UIScrollViewDelegate, UIActivityItemSource, OBAArrivalDepartureOptionsSheetDelegate, AwesomeSpotlightViewDelegate>
@property(nonatomic,strong) NSDateIntervalFormatter *timeframeFormatter;
@property(nonatomic,strong) UIRefreshControl *refreshControl;
@property(nonatomic,strong) PromiseWrapper *promiseWrapper;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) NSLock *reloadLock;
@property(nonatomic,strong) OBAArrivalsAndDeparturesForStopV2 *arrivalsAndDepartures;
@property(nonatomic,strong) OBAStopPreferencesV2 *stopPreferences;
@property(nonatomic,strong) OBARouteFilter *routeFilter;
@property(nonatomic,strong) OBAStopTableHeaderView *stopHeaderView;
@property(nonatomic,strong) OBAArrivalDepartureOptionsSheet *departureSheetHelper;
@property(nonatomic,assign,readonly) BOOL regularUIMode;
@property(nonatomic,strong) OBADrawerNavigationBar *drawerNavigationBar;
@property(nonatomic,strong) AwesomeSpotlightView *spotlightView;
@end

@implementation OBAStopViewController

- (instancetype)initWithStopID:(NSString*)stopID {
    self = [super initWithNibName:nil bundle:nil];

    if (self) {
        _reloadLock = [[NSLock alloc] init];
        _stopID = [stopID copy];
        _minutesBefore = kDefaultMinutesBefore;
        _minutesAfter = kDefaultMinutesAfter;


        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(arrivalsAndDepartures)) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:arrivalsAndDeparturesContext];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(arrivalsAndDepartures))];
    [self cancelTimers];
    [self.promiseWrapper cancel];
}

- (void)cancelTimers {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self && [keyPath isEqual:NSStringFromSelector(@selector(arrivalsAndDepartures))]) {
        BOOL oldIsNull = change[NSKeyValueChangeOldKey] == NSNull.null;
        BOOL newIsntNull = change[NSKeyValueChangeNewKey] != NSNull.null && change[NSKeyValueChangeNewKey] != nil;
        if (oldIsNull && newIsntNull) {
            [self beginUserActivity];
        }
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"stop_view_controller.stop_back_title", @"Back button title representing going back to the stop controller.");

    if (self.regularUIMode) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadData:)];
        [self createTableHeaderView];
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(reloadData:) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.refreshControl];
    }
    else {
        self.tableView.backgroundColor = UIColor.clearColor;
        self.view.backgroundColor = UIColor.clearColor;
        [self createAndInstallDrawerNavigationBar];
        [self updateDrawerTitleWithArrivalsAndDepartures:self.arrivalsAndDepartures];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    UIApplication.sharedApplication.idleTimerDisabled = YES;

    OBALogFunction();

    if (self.arrivalsAndDepartures) {
        [self beginUserActivity];
    }

    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval target:self selector:@selector(reloadData:) userInfo:nil repeats:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    [self populateTableFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    [self reloadDataAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    UIApplication.sharedApplication.idleTimerDisabled = NO;

    // Nil these out to ensure that they are recreated once the
    // view comes back into focus, which is important if the user
    // has exited this view to go to the filter & sort view controller.
    self.routeFilter = nil;
    self.stopPreferences = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];

    [self cancelTimers];
    [self.promiseWrapper cancel];
}

#pragma mark - Drawer Navigation Bar

- (void)createAndInstallDrawerNavigationBar {
    self.drawerNavigationBar = [OBADrawerNavigationBar oba_autolayoutNew];

    [self.drawerNavigationBar.closeButton addTarget:self action:@selector(closePane) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.drawerNavigationBar];
    [self.drawerNavigationBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.and.trailing.equalTo(self.view);
    }];
}

- (void)updateDrawerTitleWithArrivalsAndDepartures:(OBAArrivalsAndDeparturesForStopV2*)arrDep {
    if (!arrDep) {
        self.drawerNavigationBar.titleLabel.text = nil;
        self.drawerNavigationBar.subtitleLabel.text = nil;
        [self resizeDrawerNav];
        return;
    }

    OBABookmarkV2 *bookmark = [self.modelDAO bookmarkForArrivalAndDeparture:arrDep.arrivalsAndDepartures.firstObject];
    OBAStopV2 *stop = arrDep.stop;

    if (bookmark) {
        self.drawerNavigationBar.titleLabel.text = bookmark.name;
    }
    else {
        self.drawerNavigationBar.titleLabel.text = stop.nameWithDirection;
    }

    self.drawerNavigationBar.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"stops_controller.routes_list_fmt", @"Formatted string for a list of routes - Routes: %@"), stop.routeNamesAsString];

    if (self.inEmbedMode) {
        [self resizeDrawerNav];
    }
}

- (void)resizeDrawerNav {
    CGSize drawerNavSize = [self.drawerNavigationBar systemLayoutSizeFittingSize:CGSizeMake(CGRectGetWidth(self.view.frame), 10000) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityDefaultLow];

    CGFloat tabBarSize = self.embedDelegate.embeddedStopControllerBottomLayoutGuideLength;
    self.tableView.contentInset = UIEdgeInsetsMake(drawerNavSize.height, 0, tabBarSize, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}

#pragma mark - Notifications

- (void)willEnterForeground:(NSNotification*)note {
    // First, reload the table so that times adjust properly.
    [self.tableView reloadData];

    // And then reload remote data.
    [self reloadData:nil];
}

#pragma mark - User Activity

- (void)beginUserActivity {
    self.userActivity = [OBAHandoff createUserActivityWithName:self.arrivalsAndDepartures.stop.nameWithDirection stopID:self.arrivalsAndDepartures.stopId regionID:self.modelDAO.currentRegion.identifier];
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

- (BOOL)regularUIMode {
    return !self.inEmbedMode;
}

#pragma mark - Data Loading

- (void)reloadData:(id)sender {
    BOOL animated = !(sender == self.refreshTimer || sender == self.navigationItem.rightBarButtonItem);
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

    if (self.regularUIMode) {
        self.navigationItem.title = NSLocalizedString(@"stops_controller.title.updating", @"Title of the Stop UI Controller while it is updating its content.");
    }

    self.promiseWrapper = [self.modelService requestStopArrivalsAndDeparturesWithID:self.stopID minutesBefore:self.minutesBefore minutesAfter:self.minutesAfter];

    self.promiseWrapper.anyPromise.then(^(NetworkResponse *networkResponse) {
        OBAArrivalsAndDeparturesForStopV2 *response = networkResponse.object;
        self.navigationItem.title = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"msg_updated", @"message"), [OBADateHelpers formatShortTimeNoDate:[NSDate date]]];

        [self.modelDAO viewedArrivalsAndDeparturesForStop:response.stop];

        self.arrivalsAndDepartures = response;
        [self updateDrawerTitleWithArrivalsAndDepartures:self.arrivalsAndDepartures];
        [self.stopHeaderView populateTableHeaderFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
        [self populateTableFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    }).catch(^(NSError *error) {
        [AlertPresenter showError:error presentingController:self];
        DDLogError(@"An error occurred while displaying a stop: %@", error);
        return error;
    }).always(^{
        if (animated) {
            [self.refreshControl endRefreshing];
        }
        [self.reloadLock unlock];

        if ([self canShowCoachmarks]) {
            [self showCoachmark];
        }
        else {
            if (self.arrivalsAndDepartures.arrivalsAndDepartures.count == 0 && self.minutesAfter <= 1440) {
                if (self.minutesAfter < 180) {
                    self.minutesAfter += 60;
                }
                else if (self.minutesAfter <= 1440) {
                    self.minutesAfter += 120;
                }

                [self reloadDataAnimated:NO];
            }
        }
    });
}

- (OBATableSection*)createButtonRowSection {
    UIBarButtonItem *bookmarkButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Favorites"] style:UIBarButtonItemStylePlain target:self action:@selector(addBookmark)];
    bookmarkButton.title = NSLocalizedString(@"msg_add_bookmark", @"");

    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"filter"] style:UIBarButtonItemStylePlain target:self action:@selector(showFilterAndSortUI)];
    filterButton.accessibilityLabel = NSLocalizedString(@"stop_header_view.filter_button_accessibility_label", @"This is the Filter button in the stop header view.");
    filterButton.title = NSLocalizedString(@"stop_header_view.filter_button_title", @"This is the Filter button title in the stop header view.");

    NSMutableArray *buttons = [[NSMutableArray alloc] initWithArray:@[bookmarkButton, filterButton]];

    if (self.inEmbedMode) {
        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"refresh"] style:UIBarButtonItemStylePlain target:self action:@selector(reloadData:)];
        refreshButton.title = OBAStrings.refresh;
        [buttons addObject:refreshButton];
    }

    OBAButtonBarRow *buttonRow = [[OBAButtonBarRow alloc] initWithBarButtonItems:buttons];
    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:@[buttonRow]];

    return section;
}

- (void)populateTableFromArrivalsAndDeparturesModel:(OBAArrivalsAndDeparturesForStopV2 *)result {
    if (!result) {
        return;
    }

    NSMutableArray *sections = [NSMutableArray array];

    [sections addObject:[self createButtonRowSection]];

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
    if ([self.routeFilter filteredArrivalsAndDepartures:result.arrivalsAndDepartures].count == 0) {
        NSString *str = [NSString stringWithFormat:NSLocalizedString(@"stops.no_departures_in_next_n_minutes_format", @"No departures in the next {MINUTES} minutes"), @(self.minutesAfter)];
        OBATableRow *row = [OBATableRow disabledInfoRowWithText:str];
        OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:@[row]];
        [sections addObject:section];
    }
    else {
        // TODO: DRY up this whole thing.
        if (self.stopPreferences.sortTripsByType == OBASortTripsByDepartureTimeV2) {
            [sections addObject:[self buildClassicDepartureSectionWithDeparture:result]];
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
    }

    OBATableSection *loadMoreSection = nil;

    // "Load More Departures..."
    loadMoreSection = [self createLoadMoreDeparturesSection];

    NSString *timeframeText = [self timeframeStringForMinutesBeforeToAfter];

    if (timeframeText) {
        OBATableRow *timeframeRow = [OBATableRow disabledInfoRowWithText:timeframeText];
        [loadMoreSection addRow:timeframeRow];
    }

    if (result.lacksRealTimeData) {
        OBATableRow *scheduledExplanationRow = [OBATableRow disabledInfoRowWithText:OBAStrings.scheduledDepartureExplanation];
        [loadMoreSection addRow:scheduledExplanationRow];
    }

    [sections addObject:loadMoreSection];

    OBATableSection *moreOptionsSection = [self buildMoreOptionsSectionWithStop:result.stop];
    [sections addObject:moreOptionsSection];

    self.sections = sections;
    [self.tableView reloadData];
}

- (nullable NSString*)timeframeStringForMinutesBeforeToAfter {
    if (self.minutesBefore == kDefaultMinutesBefore && self.minutesAfter == kDefaultMinutesAfter) {
        return nil;
    }

    NSDate *beforeDate = [NSDate dateWithTimeIntervalSinceNow:-(60.0 * self.minutesBefore)];
    NSDate *afterDate = [NSDate dateWithTimeIntervalSinceNow:(60.0 * self.minutesAfter)];

    return [self.timeframeFormatter stringFromDate:beforeDate toDate:afterDate];
}

- (NSDateIntervalFormatter*)timeframeFormatter {
    if (!_timeframeFormatter) {
        _timeframeFormatter = [[NSDateIntervalFormatter alloc] init];
        _timeframeFormatter.dateStyle = NSDateIntervalFormatterNoStyle;
        _timeframeFormatter.timeStyle = NSDateIntervalFormatterShortStyle;
    }

    return _timeframeFormatter;
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
    NSUInteger minutesToArrivalAtStop = expectedArrivalDate.minutesUntil;

    OBAWalkableRow *walkableRow = [[OBAWalkableRow alloc] init];

    // Only show the user's distance/time from the stop
    // if they are a negligible distance from it.
    if (minutesToArrivalAtStop > 0) {
        walkableRow.text = [NSString stringWithFormat:NSLocalizedString(@"text_walk_to_stop_info_params",), distanceString, @(minutesToArrivalAtStop), [OBADateHelpers formatShortTimeNoDate:expectedArrivalDate]];
    }

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

    static UIEdgeInsets regularInsets;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regularInsets = cell.separatorInset;
    });

    if ([row isKindOfClass:[OBAWalkableRow class]] || [nextRow isKindOfClass:[OBAWalkableRow class]]) {
        cell.separatorInset = UIEdgeInsetsMake(0, CGRectGetWidth(bounds)/2.f, 0, CGRectGetWidth(bounds)/2.f);
    }
    else {
        cell.separatorInset = regularInsets;
    }
}

#pragma mark - Scroll View

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!self.inEmbedMode) {
        return;
    }

    CGFloat offset = scrollView.contentOffset.y;
    CGFloat height = CGRectGetHeight(self.drawerNavigationBar.frame);

    if (-offset >= height) {
        self.drawerNavigationBar.backgroundColor = [UIColor clearColor];
        [self.drawerNavigationBar hideDrawerNavigationBarShadow];
    }
    else {
        self.drawerNavigationBar.backgroundColor = [UIColor whiteColor];
        [self.drawerNavigationBar showDrawerNavigationBarShadow];
    }
}

#pragma mark - Table Section Creation

- (OBATableSection*)buildMoreOptionsSectionWithStop:(OBAStopV2*)stop {

    NSMutableArray *rows = [[NSMutableArray alloc] init];

    // Nearby Stops
    OBATableRow *nearbyStopsRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_nearby_stops", @"") action:^(OBABaseRow * _Nonnull row) {
        NearbyStopsViewController *nearby = [[NearbyStopsViewController alloc] initWithStop:stop];
        nearby.pushesResultsOntoStack = YES;
        [self pushViewController:nearby animated:YES];
    }];
    nearbyStopsRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [rows addObject:nearbyStopsRow];

    // Walking Directions (Apple Maps)
    OBATableRow *appleMaps = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"stop.walking_directions_apple_action_title", @"Title of the 'Get Walking Directions (Apple Maps)' option in the action sheet.") action:^(OBABaseRow *row) {
        NSURL *appleMapsURL = [AppInterop appleMapsWalkingDirectionsURLWithCoordinate:stop.coordinate];
        [UIApplication.sharedApplication openURL:appleMapsURL options:@{} completionHandler:nil];
    }];
    [rows addObject:appleMaps];

#if !TARGET_IPHONE_SIMULATOR
    // Walking Directions (Google Maps)
    NSURL *googleMapsURL = [AppInterop googleMapsWalkingDirectionsURLWithCoordinate:stop.coordinate];
    if ([UIApplication.sharedApplication canOpenURL:googleMapsURL]) {
        OBATableRow *googleMaps = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"stop.walking_directions_google_action_title", @"Title of the 'Get Walking Directions (Google Maps)' option in the action sheet.") action:^(OBABaseRow *row) {
            [UIApplication.sharedApplication openURL:googleMapsURL options:@{} completionHandler:nil];
        }];
        [rows addObject:googleMaps];
    }
#endif

    // Report a Problem
    OBATableRow *problem = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_report_a_problem", @"") action:^(OBABaseRow * _Nonnull row) {
        OBAReportProblemWithRecentTripsViewController * vc = [[OBAReportProblemWithRecentTripsViewController alloc] initWithStopID:self.arrivalsAndDepartures.stop.stopId];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    [rows addObject:problem];

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"stop_header_view.menu_button_accessibility_label", @"This is the '...' button in the stop header view.") rows:rows];

    return section;
}

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
        [OBAAnalytics.sharedInstance reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked load more arrivals button" value:nil];
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

    [row setAction:^(OBABaseRow *blockRow) {
        OBAArrivalAndDepartureViewController *vc = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDeparture:dep];
        [self pushViewController:vc animated:YES];
    }];

    @weakify(row);
    [row setShowAlertController:^(UIView *presentingView) {
        @strongify(row);
        [self.departureSheetHelper showActionMenuForDepartureRow:row fromPresentingView:presentingView];
    }];

    return row;
}

#pragma mark - Coachmarks

- (BOOL)canShowCoachmarks {
    BOOL tutorialViewed = [OBAApplication.sharedApplication.userDefaults boolForKey:OBAOccupancyStatusTutorialViewedDefaultsKey];
    BOOL canShow = (self.arrivalsAndDepartures.containsOccupancyPrediction && !tutorialViewed);
    return canShow;
}

- (void)showCoachmark {
    OBAClassicDepartureCell *firstVisibleCell = nil;

    for (OBAClassicDepartureCell *cell in self.tableView.visibleCells) {
        if (![cell isKindOfClass:OBAClassicDepartureCell.class]) {
            continue;
        }

        if (cell.departureView.occupancyStatusView.hidden) {
            continue;
        }

        firstVisibleCell = cell;
    }

    if (!firstVisibleCell) {
        return;
    }

    UIView *parentView = UIApplication.sharedApplication.keyWindow;
    UIView *targetView = firstVisibleCell.departureView.occupancyStatusView;
    CGRect targetFrame = [targetView convertRect:targetView.bounds toView:parentView];

    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = CGSizeMake(0, 1);
    shadow.shadowBlurRadius = OBATheme.compactPadding;
    shadow.shadowColor = UIColor.blackColor;

    NSAttributedString *coachmarkText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"stop_view_controller.predicted_departure_coachmark", @"An explanation of the predicted departure feature on the stop controller.") attributes:@{NSFontAttributeName: OBATheme.boldBodyFont, NSShadowAttributeName: shadow}];

    AwesomeSpotlight *coachmark = [[AwesomeSpotlight alloc] initWithRect:targetFrame shape:AwesomeSpotlightShapeRoundRectangle attributedText:coachmarkText margin:OBATheme.defaultEdgeInsets isAllowPassTouchesThroughSpotlight:NO];
    self.spotlightView = [[AwesomeSpotlightView alloc] initWithFrame:parentView.bounds spotlight:@[coachmark]];
    self.spotlightView.cutoutRadius = 8;
    [self.spotlightView setContinueButtonEnable:YES];
    self.spotlightView.delegate = self;

    [parentView addSubview:self.spotlightView];
    [self.spotlightView start];
}

- (void)spotlightViewDidCleanup:(AwesomeSpotlightView *)spotlightView {
    [OBAApplication.sharedApplication.userDefaults setBool:YES forKey:OBAOccupancyStatusTutorialViewedDefaultsKey];
}

#pragma mark - OBADepartureSheetDelegate

- (void)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet presentViewController:(UIViewController*)viewController fromView:(nullable UIView*)presentingView {
    [self.tableView setEditing:NO animated:YES];
    [self oba_presentViewController:viewController fromView:presentingView];
}

- (void)optionsSheet:(OBAArrivalDepartureOptionsSheet*)optionsSheet addedAlarm:(OBAAlarm*)alarm forArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalDeparture {
    NSIndexPath *indexPath = [self indexPathForModel:arrivalDeparture];

    OBAGuard(indexPath) else {
        return;
    }

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

- (void)addBookmark {
    OBABookmarkRouteDisambiguationViewController *disambiguator = [[OBABookmarkRouteDisambiguationViewController alloc] initWithArrivalsAndDeparturesForStop:self.arrivalsAndDepartures];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:disambiguator];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)createTableHeaderView {
    self.stopHeaderView = [[OBAStopTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), kTableHeaderHeight)];
    self.stopHeaderView.highContrastMode = [OBATheme useHighContrastUI];

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

- (void)pushViewController:(UIViewController*)viewController animated:(BOOL)animated {
    if (self.inEmbedMode) {
        [self.embedDelegate embeddedStopController:self pushViewController:viewController animated:YES];
    }
    else {
        [self.navigationController pushViewController:viewController animated:animated];
    }
}

#pragma mark - Embed UI

- (void)closePane {
    [self.embedDelegate embeddedStopControllerClosePane:self];
}

@end
