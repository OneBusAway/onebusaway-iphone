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
@import Apptentive;
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
#import "OBAWalkableRow.h"
#import "GKActionSheetPicker.h"
#import "OBAPushManager.h"

static NSTimeInterval const kRefreshTimeInterval = 30.0;
static CGFloat const kTableHeaderHeight = 150.f;
static NSInteger kStopsSectionTag = 101;

@interface OBAStopViewController ()<UIScrollViewDelegate, UIActivityItemSource>
@property(nonatomic,strong) UIRefreshControl *refreshControl;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) NSLock *reloadLock;
@property(nonatomic,strong) OBAArrivalsAndDeparturesForStopV2 *arrivalsAndDepartures;
@property(nonatomic,strong) OBAStopPreferencesV2 *stopPreferences;
@property(nonatomic,strong) OBARouteFilter *routeFilter;
@property(nonatomic,strong) OBAStopTableHeaderView *stopHeaderView;
@property(nonatomic,strong) NSTimer *apptentiveTimer;
@property(nonatomic,strong) GKActionSheetPicker *actionSheetPicker;
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

    // this timer is responsible for recording the user's access of the stop controller. it fires after 10 seconds
    // to ensure that the user has the opportunity to look up their departure information without a prompt appearing
    // on screen in the midst of their task. I would use -performSelector:afterDelay: or dispatch_after(), except
    // that I also want to make sure that I can appropriately cancel this timer and only show prompts from this controller.
    
    // Disable review requests - issue #854
    if ([[NSUserDefaults standardUserDefaults] boolForKey:OBAAllowReviewPromptsDefaultsKey]) {
        self.apptentiveTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(recordUserVisit:) userInfo:nil repeats:NO];
    }
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

- (OBALocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager = [OBAApplication sharedApplication].locationManager;
    }
    return _locationManager;
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

    [self.modelService requestStopForID:self.stopID minutesBefore:self.minutesBefore minutesAfter:self.minutesAfter].then(^(OBAArrivalsAndDeparturesForStopV2 *response) {
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

- (void)shareActionForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep atIndexPath:(NSIndexPath*)indexPath {
    OBAGuard(dep && indexPath) else {
        return;
    }

    OBATripDeepLink *deepLink = [[OBATripDeepLink alloc] initWithArrivalAndDeparture:dep region:self.modelDAO.currentRegion];
    NSURL *URL = deepLink.deepLinkURL;

    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[self, URL] applicationActivities:nil];

    // Present the activity controller from a popover on iPad in order to
    // avoid a crash. See bug #919.
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        controller.popoverPresentationController.sourceView = cell;
        controller.popoverPresentationController.sourceRect = cell.bounds;
    }

    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - Alarms

- (BOOL)hasAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    id val = [self.modelDAO alarmForKey:dep.alarmKey];
    return !!val;
}

- (void)promptToRemoveAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"alarms.confirm_deletion_alert_title", @"The title of the alert controller that prompts the user about whether they really want to delete this alarm.") message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"alarms.confirm_deletion_alert_cancel_button", @"This is the button that cancels the alarm deletion.") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"alarms.confirm_deletion_alert_delete_button", @"This is the button that confirms that the user really does want to delete their alarm.") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteAlarmForArrivalAndDeparture:dep];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)toggleAlarmActionForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    OBAGuard(dep) else {
        return;
    }

    if ([self hasAlarmForArrivalAndDeparture:dep]) {
        [self promptToRemoveAlarmForArrivalAndDeparture:dep];
        return;
    }

    NSUInteger alarmIncrements = dep.minutesUntilBestDeparture <= OBAAlarmIncrementsInMinutes ? 1 : OBAAlarmIncrementsInMinutes;

    NSMutableArray *items = [[NSMutableArray alloc] init];

    for (NSInteger i = dep.minutesUntilBestDeparture - (dep.minutesUntilBestDeparture % alarmIncrements); i > 0; i -=alarmIncrements) {
        NSString *pickerItemTitle = [NSString stringWithFormat:NSLocalizedString(@"alarms.picker.formatted_item", @"The format string used for picker items for choosing when an alarm should ring."), @(i)];
        [items addObject:[GKActionSheetPickerItem pickerItemWithTitle:pickerItemTitle value:@(i*60)]];
    }

    self.actionSheetPicker = [GKActionSheetPicker stringPickerWithItems:items selectCallback:^(id selected) {
        [self registerAlarmForArrivalAndDeparture:dep timeInterval:[selected doubleValue]];
    } cancelCallback:nil];

    self.actionSheetPicker.title = NSLocalizedString(@"alarms.picker.title", @"The title of the picker view that lets you choose how many minutes before your bus departs you will get an alarm.");

    if (dep.minutesUntilBestDeparture >= 10) {
        [self.actionSheetPicker selectValue:@(10*60)];
    }

    [self.actionSheetPicker presentPickerOnView:self.view];
}

- (void)deleteAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    OBAAlarm *alarm = [self.modelDAO alarmForKey:dep.alarmKey];
    NSURLRequest *request = [self.modelService.obaJsonDataSource requestWithURL:alarm.alarmURL HTTPMethod:@"DELETE"];
    [self.modelService.obaJsonDataSource performRequest:request completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
        [self.modelDAO removeAlarmWithKey:dep.alarmKey];
        // Replace with a new row and update it.
        [self updateAlarmStateForRowAtIndexPath:[self indexPathForModel:dep]];
    }];
}

- (void)updateAlarmStateForRowAtIndexPath:(NSIndexPath *)indexPath {
    OBADepartureRow *row = (OBADepartureRow *)[self rowAtIndexPath:indexPath];
    row.alarmExists = !row.alarmExists;    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)registerAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalDeparture timeInterval:(NSTimeInterval)timeInterval {
    OBAAlarm *alarm = [[OBAAlarm alloc] initWithArrivalAndDeparture:arrivalDeparture regionIdentifier:self.modelDAO.currentRegion.identifier timeIntervalBeforeDeparture:timeInterval];

    [[OBAPushManager pushManager] requestUserPushNotificationID].then(^(NSString *pushNotificationID) {
        [SVProgressHUD show];
        return [self.modelService requestAlarm:alarm userPushNotificationID:pushNotificationID];
    }).then(^(NSDictionary *serverResponse) {
        alarm.alarmURL = [NSURL URLWithString:serverResponse[@"url"]];
        [self.modelDAO addAlarm:alarm];
        // Replace with a new row and update it.
        [self updateAlarmStateForRowAtIndexPath:[self indexPathForModel:arrivalDeparture]];

        NSString *title = NSLocalizedString(@"alarms.alarm_created_alert_title", @"The title of the non-modal alert displayed when a push notification alert is registered for a vehicle departure.");
        NSString *body = [NSString stringWithFormat:NSLocalizedString(@"alarms.alarm_created_alert_body", @"The body of the non-modal alert that appears when a push notification alarm is registered."), @((NSUInteger)timeInterval / 60)];

        [AlertPresenter showSuccess:title body:body];
    }).catch(^(NSError *error) {
        [AlertPresenter showError:error];
    }).always(^{
        [SVProgressHUD dismiss];
    });
}

#pragma mark - Bookmarks

- (BOOL)hasBookmarkForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    return !![self.modelDAO bookmarkForArrivalAndDeparture:arrivalAndDeparture];
}

- (void)promptToRemoveBookmarkForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_ask_remove_bookmark", @"Tap on Remove Bookmarks on OBAStopViewController.") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_remove", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        OBABookmarkV2 *bookmark = [self.modelDAO bookmarkForArrivalAndDeparture:dep];
        [self.modelDAO removeBookmark:bookmark];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
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

        if (departure.timeIntervalUntilBestDeparture > walkingTime) {
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

        OBADepartureRow *row = [[OBADepartureRow alloc] initWithAction:^(OBABaseRow *blockRow) {
            OBAArrivalAndDepartureViewController *vc = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDeparture:dep];
            [self.navigationController pushViewController:vc animated:YES];
        }];
        row.model = dep;
        row.routeName = dep.bestAvailableName;
        row.destination = dep.tripHeadsign.capitalizedString;
        row.upcomingDepartures = @[[[OBAUpcomingDeparture alloc] initWithDepartureDate:dep.bestArrivalDepartureDate departureStatus:dep.departureStatus arrivalDepartureState:dep.arrivalDepartureState]];
        row.statusText = [OBADepartureCellHelpers statusTextForArrivalAndDeparture:dep];
        row.bookmarkExists = [self hasBookmarkForArrivalAndDeparture:dep];
        row.alarmExists = [self hasAlarmForArrivalAndDeparture:dep];
        row.hasArrived = dep.minutesUntilBestDeparture > 0;
		
        [row setShowAlertController:^(UIView *presentingView, UIAlertController *alert) {
            [self showAlertController:alert fromView:presentingView];
        }];
        [row setToggleBookmarkAction:^{
            [self toggleBookmarkActionForArrivalAndDeparture:dep];
        }];
        [row setToggleAlarmAction:^{
            [self toggleAlarmActionForArrivalAndDeparture:dep];
        }];
        [row setShareAction:^{
            [self shareActionForArrivalAndDeparture:dep atIndexPath:[self indexPathForModel:dep]];
        }];

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

- (void)showAlertController:(UIAlertController*)alert fromView:(UIView*)view {
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        alert.popoverPresentationController.sourceView = view;
        alert.popoverPresentationController.sourceRect = view.bounds;
    }
    [self presentViewController:alert animated:YES completion:nil];
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
    OBATableRow *moreDeparturesRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_load_more_departures_dots", @"") action:^{
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
        OBADepartureRow *row = [[OBADepartureRow alloc] initWithAction:^(OBABaseRow *blockRow){
            OBAArrivalAndDepartureViewController *vc = [[OBAArrivalAndDepartureViewController alloc] initWithArrivalAndDeparture:dep];
            [self.navigationController pushViewController:vc animated:YES];
        }];
        row.routeName = dep.bestAvailableName;
        row.destination = dep.tripHeadsign.capitalizedString;
        row.statusText = [OBADepartureCellHelpers statusTextForArrivalAndDeparture:dep];
        row.model = dep;
        row.bookmarkExists = [self hasBookmarkForArrivalAndDeparture:dep];
        row.alarmExists = [self hasAlarmForArrivalAndDeparture:dep];
        row.hasArrived = dep.minutesUntilBestDeparture > 0;

        [row setShowAlertController:^(UIView *presentingView, UIAlertController *alert) {
            [self showAlertController:alert fromView:presentingView];
        }];
        [row setToggleBookmarkAction:^{
            [self toggleBookmarkActionForArrivalAndDeparture:dep];
        }];
        [row setToggleAlarmAction:^{
            [self toggleAlarmActionForArrivalAndDeparture:dep];
        }];
        [row setShareAction:^{
            [self shareActionForArrivalAndDeparture:dep atIndexPath:[self indexPathForModel:dep]];
        }];

        OBAUpcomingDeparture *upcoming = [[OBAUpcomingDeparture alloc] initWithDepartureDate:dep.bestArrivalDepartureDate departureStatus:dep.departureStatus arrivalDepartureState:dep.arrivalDepartureState];
        row.upcomingDepartures = @[upcoming];
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

- (void)showActionsMenu {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    // Add Bookmark
    UIAlertAction *addBookmark = [UIAlertAction actionWithTitle:NSLocalizedString(@"msg_add_bookmark", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OBABookmarkRouteDisambiguationViewController *disambiguator = [[OBABookmarkRouteDisambiguationViewController alloc] initWithArrivalsAndDeparturesForStop:self.arrivalsAndDepartures];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:disambiguator];
        [self presentViewController:nav animated:YES completion:nil];
    }];

    // Nearby Stops
    UIAlertAction *nearbyStops = [UIAlertAction actionWithTitle:NSLocalizedString(@"msg_nearby_stops", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NearbyStopsViewController *nearby = [[NearbyStopsViewController alloc] initWithStop:self.arrivalsAndDepartures.stop];
        nearby.pushesResultsOntoStack = YES;
        [self.navigationController pushViewController:nearby animated:YES];
    }];

    // Report a Problem
    UIAlertAction *problem = [UIAlertAction actionWithTitle:NSLocalizedString(@"msg_report_a_problem", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OBAReportProblemWithRecentTripsViewController * vc = [[OBAReportProblemWithRecentTripsViewController alloc] initWithStopID:self.arrivalsAndDepartures.stop.stopId];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    }];

    [actionSheet addAction:addBookmark];
    [actionSheet addAction:nearbyStops];
    [actionSheet addAction:problem];
    [actionSheet addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)createTableHeaderView {
    self.stopHeaderView = [[OBAStopTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), kTableHeaderHeight)];
    self.stopHeaderView.highContrastMode = [OBATheme useHighContrastUI];

    [self.stopHeaderView.menuButton addTarget:self action:@selector(showActionsMenu) forControlEvents:UIControlEventTouchUpInside];
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
