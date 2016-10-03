//
//  OBAStopViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/20/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAStopViewController.h"
@import OBAKit;
#import <PromiseKit/PromiseKit.h>
#import <DateTools/DateTools.h>
#import "OneBusAway-Swift.h"
#import "OBAStopSectionHeaderView.h"
#import "OBASeparatorSectionView.h"
#import "OBAReportProblemWithRecentTripsViewController.h"
#import "OBASituationsViewController.h"
#import "OBAEditStopPreferencesViewController.h"
#import "OBAParallaxTableHeaderView.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBADepartureRow.h"
#import "OBAClassicDepartureSectionHeaderView.h"
#import "OBAAnalytics.h"
#import "OBALabelFooterView.h"
#import "OBASegmentedRow.h"
#import "OBAArrivalAndDepartureViewController.h"
#import "OBAStaticTableViewController+Builders.h"
#import "OBABookmarkRouteDisambiguationViewController.h"

static NSTimeInterval const kRefreshTimeInterval = 30.0;
static CGFloat const kTableHeaderHeight = 150.f;

@interface OBAStopViewController ()<UIScrollViewDelegate>
@property(nonatomic,strong) UIRefreshControl *refreshControl;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) NSLock *reloadLock;
@property(nonatomic,strong) OBAArrivalsAndDeparturesForStopV2 *arrivalsAndDepartures;
@property(nonatomic,strong) OBAStopPreferencesV2 *stopPreferences;
@property(nonatomic,strong) OBARouteFilter *routeFilter;
@property(nonatomic,strong) OBAParallaxTableHeaderView *parallaxHeaderView;
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
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval target:self selector:@selector(reloadData:) userInfo:nil repeats:YES];

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
    
    [self cancelTimer];
}

#pragma mark - Notifications

- (void)willEnterForeground:(NSNotification*)note {

    // First, reload the table so that times adjust properly.
    [self.tableView reloadData];

    // And then reload remote data.
    [self reloadData:nil];
}

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeStop parameters:@{ @"stopId": self.stopID }];
}

- (void)setNavigationTarget:(OBANavigationTarget *)navigationTarget {
    _stopID = [(NSObject *)[navigationTarget parameterForKey:@"stopId"] copy];
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
    [self reloadDataAnimated:YES];
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
        [self.parallaxHeaderView populateTableHeaderFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    }).catch(^(NSError *error) {
        self.navigationItem.title = NSLocalizedString(@"Error", @"");
        [AlertPresenter showWarning:NSLocalizedString(@"Error", @"") body:error.localizedDescription ?: NSLocalizedString(@"Error connecting", @"requestDidFail")];
    }).always(^{
        if (animated) {
            [self.refreshControl endRefreshing];
        }
        [self.reloadLock unlock];
    });
}

- (void)cancelTimer {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
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
        row.routeName = dep.bestAvailableName;
        row.destination = dep.tripHeadsign.capitalizedString;
        row.departsAt = [NSDate dateWithTimeIntervalSince1970:(dep.bestDepartureTime / 1000)];
        row.statusText = dep.statusText;
        row.departureStatus = dep.departureStatus;
        row.rowActions = @[[self tableViewRowActionForArrivalAndDeparture:dep]];
        row.cellReuseIdentifier = OBAClassicDepartureCellReuseIdentifier;

        [departureRows addObject:row];
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:departureRows];
    section.headerView = [[OBAClassicDepartureSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 30)];
    section.headerView.layoutMargins = UIEdgeInsetsMake(0, self.tableView.layoutMargins.left, 0, self.tableView.layoutMargins.right);
    return section;
}

#pragma mark - Row Actions

- (UITableViewRowAction*)tableViewRowActionForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    UITableViewRowAction *rowAction = nil;

    if ([self hasBookmarkForArrivalAndDeparture:dep]) {
        rowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Remove\r\nBookmark", @"") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            [self promptToRemoveBookmarkForArrivalAndDeparture:dep];
        }];
    }
    else {
        rowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Add Bookmark", @"") handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithArrivalAndDeparture:dep region:self.modelDAO.currentRegion];
            OBAEditStopBookmarkViewController *editor = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bookmark];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }];
        rowAction.backgroundColor = [OBATheme nonOpaquePrimaryColor];
    }
    return rowAction;
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
        row.destination = dep.tripHeadsign.capitalizedString;
        row.departsAt = [NSDate dateWithTimeIntervalSince1970:(dep.bestDepartureTime / 1000)];
        row.statusText = dep.statusText;
        row.departureStatus = dep.departureStatus;
        [rows addObject:row];
    }

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:rows];
    section.headerView = ({
        OBAStopSectionHeaderView *header = [[OBAStopSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 44.f)];
        header.layoutMargins = self.tableView.layoutMargins;
        header.routeNameText = title;
        header;
    });
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

    // Report a Problem
    OBATableRow *problem = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Report a Problem", @"") action:^{
        OBAReportProblemWithRecentTripsViewController * vc = [[OBAReportProblemWithRecentTripsViewController alloc] initWithStopID:stop.stopId];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    [actionRows addObject:problem];

    // Filter/Sort Arrivals
    OBATableRow *filter = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Filter & Sort Routes", @"") action:^{
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
    self.parallaxHeaderView = [[OBAParallaxTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), kTableHeaderHeight)];
    self.parallaxHeaderView.highContrastMode = [OBAApplication sharedApplication].useHighContrastUI;

    self.tableView.tableHeaderView = self.parallaxHeaderView;
}

@end
