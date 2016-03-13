//
//  OBAStopViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/20/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAStopViewController.h"
#import <OBAKit/OBAKit.h>
#import <PromiseKit/PromiseKit.h>
#import <DateTools/DateTools.h>
#import "OBAStopSectionHeaderView.h"
#import "OBASeparatorSectionView.h"
#import "OBAArrivalAndDepartureViewController.h"
#import "OBAReportProblemViewController.h"
#import "OBASituationsViewController.h"
#import "OBAEditStopPreferencesViewController.h"
#import "OBAParallaxTableHeaderView.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBAClassicDepartureRow.h"
#import "OBAClassicDepartureSectionHeaderView.h"
#import "OBAAnalytics.h"
#import "OBALabelFooterView.h"
#import "OBASegmentedRow.h"

#define ENABLE_PARALLAX_WHICH_NEEDS_FIXING 0

static NSTimeInterval const kRefreshTimeInterval = 30.0;
static CGFloat const kTableHeaderHeight = 150.f;

@interface OBAStopViewController ()<UIScrollViewDelegate>
@property(nonatomic,strong) UIRefreshControl *refreshControl;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) NSLock *reloadLock;
@property(nonatomic,strong) OBAArrivalsAndDeparturesForStopV2 *arrivalsAndDepartures;
@property(nonatomic,assign) BOOL hideFilteredRoutes;

@property(nonatomic,strong) OBAParallaxTableHeaderView *parallaxHeaderView;
@end

@implementation OBAStopViewController

+ (UIViewController*)stopControllerWithStopID:(NSString*)stopID {
    return [[OBAStopViewController alloc] initWithStopID:stopID];
}

- (instancetype)initWithStopID:(NSString*)stopID {
    self = [super initWithNibName:nil bundle:nil];
    
    if (self) {
        _reloadLock = [[NSLock alloc] init];
        _stopID = [stopID copy];
        _minutesBefore = 5;
        _minutesAfter = 35;
        _hideFilteredRoutes = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createTableHeaderView];

#if ENABLE_PARALLAX_WHICH_NEEDS_FIXING
    self.tableView.contentInset = UIEdgeInsetsMake(kTableHeaderHeight, 0, 0, 0);
    self.tableView.contentOffset = CGPointMake(0, -kTableHeaderHeight);
#endif

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval target:self selector:@selector(reloadData:) userInfo:nil repeats:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    [self reloadData:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self cancelTimer];
}

#pragma mark - Notifications

- (void)willEnterForeground:(NSNotification*)note {
    [self reloadData:nil];
}

#pragma mark - UIScrollViewDelegate

#if ENABLE_PARALLAX_WHICH_NEEDS_FIXING
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGRect headerRect = CGRectMake(0, -kTableHeaderHeight, CGRectGetWidth(scrollView.frame), kTableHeaderHeight);
    
    if (scrollView.contentOffset.y < -kTableHeaderHeight) {
        headerRect.origin.y = scrollView.contentOffset.y;
        headerRect.size.height = -scrollView.contentOffset.y;
    }

    self.parallaxHeaderView.frame = headerRect;
}
#endif

#pragma mark - OBANavigationTargetAware

- (OBANavigationTarget *)navigationTarget {
    return [OBANavigationTarget target:OBANavigationTargetTypeStop parameters:@{ @"stopId": self.stopID }];
}

- (void)setNavigationTarget:(OBANavigationTarget *)navigationTarget {
    _stopID = [[navigationTarget parameterForKey:@"stopId"] copy];
    [self reloadData:nil];
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
    
    __block NSString *message = nil;
    [[OBAApplication sharedApplication].modelService requestStopForID:self.stopID minutesBefore:self.minutesBefore minutesAfter:self.minutesAfter].then(^(OBAArrivalsAndDeparturesForStopV2 *response) {
        self.navigationItem.title = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Updated", @"message"), [OBACommon getTimeAsString]];
        [[NSNotificationCenter defaultCenter] postNotificationName:OBAViewedArrivalsAndDeparturesForStopNotification object:response.stop];

        self.arrivalsAndDepartures = response;

        // This will update existing bookmarks as they are accessed and ensure
        // that they have the correct coordinate and region set on them.
        [OBAStopViewController updateBookmarkForStop:self.arrivalsAndDepartures.stop inModelDAO:[OBAApplication sharedApplication].modelDao];

        [self populateTableFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
        [self.parallaxHeaderView populateTableHeaderFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    }).catch(^(NSError *error) {
        message = error.localizedDescription ?: NSLocalizedString(@"Error connecting", @"requestDidFail");
        self.navigationItem.title = message;
    }).finally(^{
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
    OBAModelDAO *modelDao = [OBAApplication sharedApplication].modelDao;
    OBAStopPreferencesV2 *prefs = [modelDao stopPreferencesForStopWithId:result.stop.stopId];

    NSMutableArray *sections = [NSMutableArray array];

    // Toggle showing/hiding filtered routes.
    if (prefs.hasFilteredRoutes) {
        [sections addObject:[self createToggleDepartureFilterSection]];
    }

    // Service Alerts
    OBAServiceAlertsModel *serviceAlerts = [modelDao getServiceAlertsModelForSituations:result.situations];
    if (serviceAlerts.totalCount > 0) {
        [sections addObject:[self createServiceAlertsSection:result serviceAlerts:serviceAlerts]];
    }

    // Departures
    // TODO: DRY up this whole thing.
    if (prefs.sortTripsByType == OBASortTripsByDepartureTimeV2) {
        NSMutableArray *departureRows = [NSMutableArray array];

        for (OBAArrivalAndDepartureV2 *dep in result.arrivalsAndDepartures) {

            if (![self shouldShowRouteID:dep.routeId forPrefs:prefs]) {
                continue;
            }

            NSString *dest = [[OBAPresentation getTripHeadsignForArrivalAndDeparture:dep] capitalizedString];
            OBAClassicDepartureRow *row = [[OBAClassicDepartureRow alloc] initWithRouteName:dep.bestAvailableName destination:dest departsAt:[NSDate dateWithTimeIntervalSince1970:(dep.bestDepartureTime / 1000)] statusText:[dep statusText] departureStatus:[dep departureStatus] action:^{
                OBAArrivalAndDepartureViewController *vc = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDeparture:dep];
                [self.navigationController pushViewController:vc animated:YES];
            }];

            [departureRows addObject:row];
        }

        OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:departureRows];
        section.headerView = [[OBAClassicDepartureSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 30)];
        section.headerView.layoutMargins = UIEdgeInsetsMake(0, self.tableView.layoutMargins.left, 0, self.tableView.layoutMargins.right);

        [sections addObject:section];
    }
    else {
        NSDictionary *groupedArrivals = [OBAStopViewController groupPredictedArrivalsOnRoute:result.arrivalsAndDepartures];
        NSArray *arrivalKeys = [groupedArrivals.allKeys sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
        for (NSString *key in arrivalKeys) {
            NSArray<OBAArrivalAndDepartureV2*> *departures = groupedArrivals[key];

            // Exclude table sections for routes that the user has disabled and routes without departures.
            if (departures.count > 0 && [self shouldShowRouteID:departures[0].routeId forPrefs:prefs]) {
                [sections addObject:[self createDepartureSectionWithTitle:key fromDepartures:departures]];
            }
        }
    }

    // "Load More Departures..."
    OBATableSection *loadMoreSection = [self createLoadMoreDeparturesSection];
    if ([self.class departuresLackRealTimeData:result]) {
        loadMoreSection.footerView = ({
            OBALabelFooterView *label = [[OBALabelFooterView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 20)];
            label.text = NSLocalizedString(@"*'Scheduled': no vehicle location data available", @"");

            label;
        });
    }
    [sections addObject:loadMoreSection];

    // Actions
    [sections addObject:[self createActionSectionWithStop:result.stop modelDAO:modelDao]];

    self.sections = sections;
    [self.tableView reloadData];
}

#pragma mark - Table Section Creation

- (OBATableSection*)createToggleDepartureFilterSection {

    OBASegmentedRow *segmentedRow = [[OBASegmentedRow alloc] initWithSelectionChange:^(NSUInteger selectedIndex) {
        self.hideFilteredRoutes = !self.hideFilteredRoutes;
        [self populateTableFromArrivalsAndDeparturesModel:self.arrivalsAndDepartures];
    }];
    segmentedRow.items = @[NSLocalizedString(@"Show All Departures", @""), NSLocalizedString(@"Show Filtered Departures", @"")];

    segmentedRow.selectedItemIndex = self.hideFilteredRoutes ? 1 : 0;

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

        NSString *dest = [[OBAPresentation getTripHeadsignForArrivalAndDeparture:dep] capitalizedString];
        NSString *status = [dep statusText];

        OBADepartureRow *row = [[OBADepartureRow alloc] initWithDestination:dest departsAt:[NSDate dateWithTimeIntervalSince1970:(dep.bestDepartureTime / 1000)] statusText:status departureStatus:[dep departureStatus] action:^{
            OBAArrivalAndDepartureViewController *vc = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDeparture:dep];
            [self.navigationController pushViewController:vc animated:YES];
        }];

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
    OBABookmarkV2 *bookmark = [modelDAO bookmarkForStop:stop];
    NSString *bookmarksTitle = bookmark ? NSLocalizedString(@"Edit Bookmark", @"") : NSLocalizedString(@"Add to Bookmarks", @"");
    OBATableRow *addToBookmarks = [[OBATableRow alloc] initWithTitle:bookmarksTitle action:^{
        OBAEditStopBookmarkViewController *viewController = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bookmark forStop:stop];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:viewController];
        [self presentViewController:nav animated:YES completion:nil];
    }];
    [actionRows addObject:addToBookmarks];

    // Report a Problem
    OBATableRow *problem = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Report a Problem", @"") action:^{
        OBAReportProblemViewController *vc = [[OBAReportProblemViewController alloc] initWithStop:stop];
        [self.navigationController pushViewController:vc animated:YES];
    }];
    problem.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [actionRows addObject:problem];

    // Filter/Sort Arrivals
    OBATableRow *filter = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Filter & Sort Routes", @"") action:^{
        OBAEditStopPreferencesViewController *vc = [[OBAEditStopPreferencesViewController alloc] initWithStop:stop];
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

- (OBATableSection*)createServiceAlertsSection:(OBAArrivalsAndDeparturesForStopV2 *)result serviceAlerts:(OBAServiceAlertsModel*)serviceAlerts {
    OBATableRow *serviceAlertsRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"View Service Alerts", @"") action:^{
        [OBASituationsViewController showSituations:result.situations navigationController:self.navigationController args:nil];
    }];

    serviceAlertsRow.image = [self.class iconForServiceAlerts:serviceAlerts];

    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil rows:@[serviceAlertsRow]];
    return section;
}

#pragma mark - Miscellaneous UI and Utilities

+ (UIImage*)iconForServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts {
    if (serviceAlerts.unreadCount > 0) {
        NSString *imageName = [serviceAlerts.unreadMaxSeverity isEqual:@"noImpact"] ? @"Alert-Info" : @"Alert";
        return [UIImage imageNamed:imageName];
    }
    else {
        NSString *imageName = [serviceAlerts.maxSeverity isEqual:@"noImpact"] ? @"Alert-Info-Grayscale" : @"AlertGrayscale";
        return [UIImage imageNamed:imageName];
    }
}

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
    self.parallaxHeaderView.highContrastMode = [[OBAApplication sharedApplication] useHighContrastUI];

#if ENABLE_PARALLAX_WHICH_NEEDS_FIXING
    [self.tableView addSubview:self.parallaxHeaderView];
#else
    self.tableView.tableHeaderView = self.parallaxHeaderView;
#endif
}

- (BOOL)shouldShowRouteID:(NSString*)routeID forPrefs:(OBAStopPreferencesV2*)prefs {
    if (!self.hideFilteredRoutes) {
        return YES;
    }
    else {
        return ![prefs isRouteIDDisabled:routeID];
    }
}

+ (BOOL)departuresLackRealTimeData:(OBAArrivalsAndDeparturesForStopV2*)dep {
    for (OBAArrivalAndDepartureV2 *ref in dep.arrivalsAndDepartures) {
        if (!ref.hasRealTimeData) {
            return YES;
        }
    }

    return NO;
}

#pragma mark - Private

+ (void)updateBookmarkForStop:(OBAStopV2*)stop inModelDAO:(OBAModelDAO*)modelDAO {
    OBABookmarkV2 *bookmark = [modelDAO bookmarkForStop:stop];

    if (bookmark) {
        bookmark.coordinate = stop.coordinate;
        bookmark.regionIdentifier = modelDAO.region.identifier;
        [modelDAO saveExistingBookmark:bookmark];
    }
}

@end
