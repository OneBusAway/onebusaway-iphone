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
#import "OneBusAway-Swift.h"
#import "OBASeparatorSectionView.h"
#import "OBAReportProblemWithRecentTripsViewController.h"
#import "OBAEditStopPreferencesViewController.h"
#import "OBAStopTableHeaderView.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBADepartureRow.h"
#import "OBAAnalytics.h"
#import "OBALabelFooterView.h"
#import "OBASegmentedRow.h"
#import "OBAArrivalAndDepartureViewController.h"
#import "OBAStaticTableViewController+Builders.h"
#import "OBABookmarkRouteDisambiguationViewController.h"
#import "Apptentive.h"
#import "OBAWalkableRow.h"

static NSTimeInterval const kRefreshTimeInterval = 30.0;
static CGFloat const kTableHeaderHeight = 150.f;
static NSInteger kStopsSectionTag = 101;

@interface OBAStopViewController ()<UIScrollViewDelegate>
@property(nonatomic,strong) UIRefreshControl *refreshControl;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) NSLock *reloadLock;
@property(nonatomic,strong) OBAArrivalsAndDeparturesForStopV2 *arrivalsAndDepartures;
@property(nonatomic,strong) OBAStopPreferencesV2 *stopPreferences;
@property(nonatomic,strong) OBARouteFilter *routeFilter;
@property(nonatomic,strong) OBAStopTableHeaderView *stopHeaderView;
@property(nonatomic,strong) NSTimer *apptentiveTimer;
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

    [self.apptentiveTimer invalidate];
    self.apptentiveTimer = nil;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

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

    // this timer is responsible for recording the user's access of the stop controller. it fires after 10 seconds
    // to ensure that the user has the opportunity to look up their departure information without a prompt appearing
    // on screen in the midst of their task. I would use -performSelector:afterDelay: or dispatch_after(), except
    // that I also want to make sure that I can appropriately cancel this timer and only show prompts from this controller.
    self.apptentiveTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(recordUserVisit:) userInfo:nil repeats:NO];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    [self populateTableFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    [self reloadDataAnimated:NO];
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
}

#pragma mark - Apptentive

- (void)recordUserVisit:(NSTimer*)timer {
    [[Apptentive sharedConnection] engage:@"stop_view_controller" fromViewController:self];
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

- (OBAModelService*)modelService {
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

    self.navigationItem.title = NSLocalizedString(@"Updating...", @"Title of the Stop UI Controller while it is updating its content.");

    [self.modelService requestStopForID:self.stopID minutesBefore:self.minutesBefore minutesAfter:self.minutesAfter].then(^(OBAArrivalsAndDeparturesForStopV2 *response) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Updated", @"message"), [OBACommon getTimeAsString]];
        [self.modelDAO viewedArrivalsAndDeparturesForStop:response.stop];

        self.arrivalsAndDepartures = response;

        [self populateTableFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
        [self.stopHeaderView populateTableHeaderFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    }).catch(^(NSError *error) {
        [AlertPresenter showWarning:NSLocalizedString(@"Error", @"") body:error.localizedDescription ?: NSLocalizedString(@"Error connecting.", @"requestDidFail")];
        DDLogError(@"An error occurred while displaying a stop: %@", error);
        return error;
    }).then(^{
        return [OBAWalkingDirections requestWalkingETA:self.arrivalsAndDepartures.stop.coordinate];
    }).then(^(MKETAResponse *ETA) {
        [self insertWalkingIndicatorIntoTable:ETA];
        self.stopHeaderView.walkingETA = ETA;
    }).catch(^(NSError *error) {
        DDLogError(@"Unable to calculate walk time to stop: %@", error);
        self.stopHeaderView.walkingETA = nil;
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
        loadMoreSection.footerView = ({
            OBALabelFooterView *label = [[OBALabelFooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 20)];
            label.text = [OBAStrings scheduledDepartureExplanation];
            label;
        });
    }
    [sections addObject:loadMoreSection];

    // Actions
    [sections addObject:[self createActionSectionWithStop:result.stop modelDAO:self.modelDAO]];

    self.sections = sections;
    [self.tableView reloadData];
}

- (OBATableSection *)buildClassicDepartureSectionWithDeparture:(OBAArrivalsAndDeparturesForStopV2 *)result {
    NSMutableArray *departureRows = [NSMutableArray array];

    for (OBAArrivalAndDepartureV2 *dep in result.arrivalsAndDepartures) {
        if (![self.routeFilter shouldShowRouteID:dep.routeId]) {
            continue;
        }

        OBADepartureRow *row = [[OBADepartureRow alloc] initWithAction:^(OBABaseRow *blockRow) {
            OBAArrivalAndDepartureViewController *vc = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDeparture:dep];
            [self.navigationController pushViewController:vc animated:YES];
        }];
        row.model = dep;
        row.routeName = dep.bestAvailableName;
        row.destination = dep.tripHeadsign.capitalizedString;
        row.upcomingDepartures = @[[[OBAUpcomingDeparture alloc] initWithDepartureDate:dep.bestDeparture departureStatus:dep.departureStatus]];
        row.statusText = dep.statusText;
        row.bookmarkExists = [self hasBookmarkForArrivalAndDeparture:dep];

        [row setToggleBookmarkAction:^{
            [self toggleBookmarkActionForArrivalAndDeparture:dep];
        }];
        [row setShareAction:^{
            [self shareActionForArrivalAndDeparture:dep];
        }];

        [departureRows addObject:row];
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:departureRows];
    section.tag = kStopsSectionTag;

    return section;
}

#pragma mark - Row Actions

- (void)toggleBookmarkActionForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    if ([self hasBookmarkForArrivalAndDeparture:dep]) {
        [self promptToRemoveBookmarkForArrivalAndDeparture:dep];
    }
    else {
        [self.tableView setEditing:NO animated:YES];
        OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithArrivalAndDeparture:dep region:self.modelDAO.currentRegion];
        OBAEditStopBookmarkViewController *editor = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bookmark];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
}

- (void)shareActionForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    OBATripDeepLink *deepLink = [[OBATripDeepLink alloc] initWithArrivalAndDeparture:dep region:self.modelDAO.currentRegion];
    [self shareDeepLinkURL:deepLink.deepLinkURL];
}

#pragma mark - Bookmarks

- (BOOL)hasBookmarkForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    return !![self.modelDAO bookmarkForArrivalAndDeparture:arrivalAndDeparture];
}

- (void)promptToRemoveBookmarkForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure you want to remove this bookmark?", @"Tap on Remove Bookmarks on OBAStopViewController.") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remove", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        OBABookmarkV2 *bookmark = [self.modelDAO bookmarkForArrivalAndDeparture:dep];
        [self.modelDAO removeBookmark:bookmark];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Walking

- (void)insertWalkingIndicatorIntoTable:(MKETAResponse*)ETA {
    OBAGuard(ETA) else {
        return;
    }

    NSMutableArray<NSIndexPath*> *indexPaths = [NSMutableArray array];

    NSArray *sections = self.sections;
    for (NSUInteger i=0; i<sections.count; i++) {
        OBATableSection *section = sections[i];

        if (section.tag != kStopsSectionTag) {
            continue;
        }

        for (NSUInteger j=0; j<section.rows.count; j++) {
            OBADepartureRow *row = section.rows[j];
            OBAArrivalAndDepartureV2 *model = row.model;

            if (![row isKindOfClass:[OBADepartureRow class]]) {
                continue;
            }

            if (![model isKindOfClass:[OBAArrivalAndDepartureV2 class]]) {
                continue;
            }

            if (model.timeIntervalUntilBestDeparture > ETA.expectedTravelTime) {
                // this is the first row that departs after our walk time. Use it.
                [indexPaths addObject:[NSIndexPath indexPathForRow:j inSection:i]];
                break;
            }
        }
    }

    [self.tableView beginUpdates];

    for (NSIndexPath *path in indexPaths) {
        [self insertRow:[[OBAWalkableRow alloc] init] atIndexPath:path animation:UITableViewRowAnimationAutomatic];
    }

    [self.tableView endUpdates];
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

- (OBATableSection*)createToggleDepartureFilterSection {
    OBASegmentedRow *segmentedRow = [[OBASegmentedRow alloc] initWithSelectionChange:^(NSUInteger selectedIndex) {
        self.routeFilter.showFilteredRoutes = !self.routeFilter.showFilteredRoutes;
        [self populateTableFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    }];
    segmentedRow.items = @[NSLocalizedString(@"All Departures", @""), NSLocalizedString(@"Filtered Departures", @"")];

    segmentedRow.selectedItemIndex = self.routeFilter.showFilteredRoutes ? 0 : 1;

    return [[OBATableSection alloc] initWithTitle:nil rows:@[segmentedRow]];
}

- (OBATableSection*)createLoadMoreDeparturesSection {
    OBATableRow *moreDeparturesRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Load More Departures...", @"") action:^{
        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategoryUIAction action:@"button_press" label:@"Clicked load more arrivals button" value:nil];
        self.minutesAfter += 30;
        [self reloadDataAnimated:NO];
    }];
    moreDeparturesRow.textAlignment = NSTextAlignmentCenter;
    return [[OBATableSection alloc] initWithTitle:nil rows:@[moreDeparturesRow]];
}

- (OBATableSection*)createDepartureSectionWithTitle:(NSString*)title fromDepartures:(NSArray<OBAArrivalAndDepartureV2*>*)departures {
    NSMutableArray *rows = [[NSMutableArray alloc] init];

    for (OBAArrivalAndDepartureV2* dep in departures) {
        OBADepartureRow *row = [[OBADepartureRow alloc] initWithAction:^(OBABaseRow *blockRow){
            OBAArrivalAndDepartureViewController *vc = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDeparture:dep];
            [self.navigationController pushViewController:vc animated:YES];
        }];
        row.routeName = dep.bestAvailableName;
        row.destination = dep.tripHeadsign.capitalizedString;
        row.statusText = dep.statusText;
        row.model = dep;

        OBAUpcomingDeparture *upcoming = [[OBAUpcomingDeparture alloc] initWithDepartureDate:dep.bestDeparture departureStatus:dep.departureStatus];

        row.upcomingDepartures = @[upcoming];
        [rows addObject:row];
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:title rows:rows];
    section.tag = kStopsSectionTag;
    return section;
}

- (OBATableSection*)createActionSectionWithStop:(OBAStopV2*)stop modelDAO:(OBAModelDAO*)modelDAO {
    NSMutableArray *actionRows = [[NSMutableArray alloc] init];

    // Add to Bookmarks
    NSString *bookmarksTitle = NSLocalizedString(@"Add Bookmark", @"");
    OBATableRow *addToBookmarks = [[OBATableRow alloc] initWithTitle:bookmarksTitle action:^{
        OBABookmarkRouteDisambiguationViewController *disambiguator = [[OBABookmarkRouteDisambiguationViewController alloc] initWithArrivalsAndDeparturesForStop:self.arrivalsAndDepartures];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:disambiguator];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    [actionRows addObject:addToBookmarks];

    // Nearby Stops
    OBATableRow *nearbyStops = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Nearby Stops",) action:^{
        NearbyStopsViewController *nearby = [[NearbyStopsViewController alloc] initWithStop:self.arrivalsAndDepartures.stop];
        [self.navigationController pushViewController:nearby animated:YES];
    }];
    nearbyStops.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [actionRows addObject:nearbyStops];

    // Report a Problem
    OBATableRow *problem = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Report a Problem", @"") action:^{
        OBAReportProblemWithRecentTripsViewController * vc = [[OBAReportProblemWithRecentTripsViewController alloc] initWithStopID:stop.stopId];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    [actionRows addObject:problem];

    // Filter/Sort Arrivals
    OBATableRow *filter = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Sort & Filter Routes",) action:^{
        OBAEditStopPreferencesViewController *vc = [[OBAEditStopPreferencesViewController alloc] initWithModelDAO:modelDAO stop:stop];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    filter.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [actionRows addObject:filter];

    OBATableSection *actionSection = [[OBATableSection alloc] initWithTitle:nil rows:actionRows];
    actionSection.headerView = ({
        OBASeparatorSectionView *separator = [[OBASeparatorSectionView alloc] init];
        separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        separator;
    });

    return actionSection;
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

- (void)createTableHeaderView {
    self.stopHeaderView = [[OBAStopTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), kTableHeaderHeight)];
    self.stopHeaderView.highContrastMode = [OBATheme useHighContrastUI];

    self.tableView.tableHeaderView = self.stopHeaderView;
}

- (void)shareDeepLinkURL:(NSURL*)URL {
    NSString *activityItem = [NSString stringWithFormat:NSLocalizedString(@"Follow my trip: %@", @"Sharing link activity item in the stop view controller"), URL.absoluteString];

    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[activityItem] applicationActivities:nil];

    [self presentViewController:controller animated:YES completion:nil];
}

@end
