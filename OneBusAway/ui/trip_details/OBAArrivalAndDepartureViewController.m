//
//  OBAArrivalAndDepartureViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAArrivalAndDepartureViewController.h"
#import "OBAStaticTableViewController+Builders.h"
#import "OBATripScheduleMapViewController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBAVehicleDetailsController.h"
#import "OBASeparatorSectionView.h"
#import "OBAClassicDepartureView.h"
#import "OBATripScheduleSectionBuilder.h"
#import "OBAArrivalAndDepartureSectionBuilder.h"
#import "OBAArrivalDepartureRow.h"

static NSTimeInterval const kRefreshTimeInterval = 30;

@interface OBAArrivalAndDepartureViewController ()
@property(nonatomic,strong) OBATripDetailsV2 *tripDetails;
@property(nonatomic,strong) OBAClassicDepartureView *tableHeaderView;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) UIRefreshControl *refreshControl;
@property(nonatomic,strong) NSLock *reloadLock;
@property(nonatomic,copy) OBATripDeepLink *link;
@end

// TODO: lots of this is duplicated from OBAStopViewController.
// Time to start considering how exactly it gets DRY'd up.

@implementation OBAArrivalAndDepartureViewController

- (instancetype)init {
    self = [super init];

    if (self ) {
        _reloadLock = [[NSLock alloc] init];
    }
    return self;
}

- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    self = [self init];

    if (self) {
        _arrivalAndDeparture = arrivalAndDeparture;
    }
    return self;
}

- (instancetype)initWithTripDeepLink:(OBATripDeepLink*)link {
    self = [self init];

    if (self) {
        _link = [link copy];
    }
    return self;
}

#pragma mark - View Controller

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"msg_show_map", @"") style:UIBarButtonItemStylePlain target:self action:@selector(showMap:)];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    OBALogFunction();

    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:kRefreshTimeInterval target:self selector:@selector(reloadData:) userInfo:nil repeats:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    [self reloadDataAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];

    [self cancelTimer];
}

#pragma mark - Actions

- (void)showMap:(id)sender {
    OBATripScheduleMapViewController *vc = [[OBATripScheduleMapViewController alloc] init];
    vc.tripInstance = self.arrivalAndDeparture.tripInstance;
    vc.currentStopId = self.arrivalAndDeparture.stopId;

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Notifications

- (void)willEnterForeground:(NSNotification*)note {

    // First, reload the table so that times adjust properly.
    [self.tableView reloadData];

    // And then reload remote data.
    [self reloadData:nil];
}

#pragma mark - Timer/Refresh Control

- (void)reloadData:(id)sender {
    [self reloadDataAnimated:YES];
}

- (void)cancelTimer {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

#pragma mark - Lazy Loading

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

#pragma mark - Data Loading

- (void)reloadDataAnimated:(BOOL)animated {
    // If we're already loading data, then just bail.
    if (![self.reloadLock tryLock]) {
        return;
    }

    if (animated) {
        [self.refreshControl beginRefreshing];
    }

    [self promiseArrivalDeparture].then(^(OBAArrivalAndDepartureV2 *arrivalAndDeparture) {
        self.arrivalAndDeparture = arrivalAndDeparture;
        return [self.modelService requestTripDetailsForTripInstance:self.arrivalAndDeparture.tripInstance];
    }).then(^(OBATripDetailsV2 *tripDetails) {
        self.tripDetails = tripDetails;
        [self populateTableWithArrivalAndDeparture:self.arrivalAndDeparture tripDetails:self.tripDetails];
    }).catch(^(NSError *error) {
        // TODO: handle error.
    }).always(^{
        if (animated) {
            [self.refreshControl endRefreshing];
        }
        [self.reloadLock unlock];
    });
}

- (AnyPromise*)promiseArrivalDeparture {
    if (self.link) {
        return [self.modelService requestArrivalAndDepartureWithTripDeepLink:self.link];
    }
    else {
        return [self.modelService requestArrivalAndDeparture:self.arrivalAndDeparture.instance];
    }
}

- (void)populateTableWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture tripDetails:(OBATripDetailsV2*)tripDetails {

    NSMutableArray *sections = [[NSMutableArray alloc] init];

    NSUInteger currentStopIndex = [OBATripScheduleSectionBuilder indexOfStopID:arrivalAndDeparture.stopId inSchedule:tripDetails.schedule];

    // Service Alerts Section
    OBATableSection *serviceAlertsSection = [self createServiceAlertsSection:arrivalAndDeparture];
    if (serviceAlertsSection) {
        [sections addObject:serviceAlertsSection];
    }

    // Stops Section
    OBATableSection *stopsSection = [OBATripScheduleSectionBuilder buildStopsSection:tripDetails arrivalAndDeparture:arrivalAndDeparture currentStopIndex:currentStopIndex navigationController:self.navigationController];
    stopsSection.headerView = [self buildTableHeaderViewWithArrivalAndDeparture:arrivalAndDeparture];
    [sections addObject:stopsSection];

    // Actions Section
    [sections addObject:[self.class createActionsSection:arrivalAndDeparture navigationController:self.navigationController]];

    self.sections = sections;
    [self.tableView reloadData];

    // Scroll the user's current stop to the top of the list
    if (currentStopIndex != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:currentStopIndex inSection:0];

        // only scroll if the indexPath actually exists...
        // but that does raise the question of how we'd end
        // up in a situation where that was not the case.
        if (self.sections.count > indexPath.section && self.sections[indexPath.section].rows.count > indexPath.row) {
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        else {
            DDLogError(@"%s: We really shouldn't end up here...", __PRETTY_FUNCTION__);
        }
    }
}

#pragma mark - Section/Row Construction

- (nullable OBATableSection*)createServiceAlertsSection:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    OBAServiceAlertsModel* serviceAlerts = [self.modelDAO getServiceAlertsModelForSituations:arrivalAndDeparture.situations];

    if (serviceAlerts.totalCount == 0) {
        return nil;
    }

    return [self createServiceAlertsSection:arrivalAndDeparture serviceAlerts:serviceAlerts];
}

- (UIView*)buildTableHeaderViewWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    OBAClassicDepartureView *tableHeaderView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
    tableHeaderView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    tableHeaderView.departureRow = [OBAArrivalAndDepartureSectionBuilder createDepartureRow:arrivalAndDeparture];

    return [self buildTableHeaderWrapperView:tableHeaderView];
}

- (UIView*)buildTableHeaderWrapperView:(UIView*)tableHeaderView {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *blurContainer = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    blurContainer.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 60);

    tableHeaderView.frame = CGRectInset(blurContainer.bounds, [OBATheme defaultPadding], 0);
    [blurContainer.contentView addSubview:tableHeaderView];

    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, 59, CGRectGetWidth(blurContainer.contentView.frame), 1)];
    bottomLine.backgroundColor = [OBATheme borderColor];
    bottomLine.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    [blurContainer.contentView addSubview:bottomLine];

    return blurContainer;
}

+ (OBATableSection*)createActionsSection:(OBAArrivalAndDepartureV2*)arrivalAndDeparture navigationController:(UINavigationController*)navigationController {
    OBATableSection *actionsSection = [[OBATableSection alloc] init];
    actionsSection.headerView = [OBASeparatorSectionView new];

    [actionsSection addRowWithBlock:^OBABaseRow * {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_minus_report_problem_this_trip", @"") action:^{
            OBAReportProblemWithTripViewController *vc = [[OBAReportProblemWithTripViewController alloc] initWithTripInstance:arrivalAndDeparture.tripInstance trip:arrivalAndDeparture.trip];
            vc.currentStopId = arrivalAndDeparture.stopId;
            [navigationController pushViewController:vc animated:YES];
        }];
        return tableRow;
    }];

    [actionsSection addRowWithBlock:^OBABaseRow * {

        OBATableRow *tableRow = nil;

        if (arrivalAndDeparture.tripStatus.vehicleId.length > 0) {
            tableRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_vehicle_info", @"") action:^{
                OBAVehicleDetailsController *vc = [[OBAVehicleDetailsController alloc] initWithVehicleId:arrivalAndDeparture.tripStatus.vehicleId];
                [navigationController pushViewController:vc animated:YES];
            }];
        }
        else {
            tableRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"msg_no_vehicle_info_available", @"") action:nil];
            tableRow.selectionStyle = UITableViewCellSelectionStyleNone;
            tableRow.titleColor = [OBATheme darkDisabledColor];
        }

        return tableRow;
    }];

    return actionsSection;
}

@end
