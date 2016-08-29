//
//  OBAArrivalAndDepartureViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/18/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAArrivalAndDepartureViewController.h"
#import "OBAStaticTableViewController+Builders.h"
#import "OBAApplication.h"
#import "OBAClassicDepartureRow.h"
#import "OBATripScheduleMapViewController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBAVehicleDetailsController.h"
#import "OBASeparatorSectionView.h"
#import "OBAClassicDepartureView.h"
#import "OBATripScheduleSectionBuilder.h"
#import "OBAArrivalAndDepartureSectionBuilder.h"

static NSTimeInterval const kRefreshTimeInterval = 30;

@interface OBAArrivalAndDepartureViewController ()
@property(nonatomic,strong) OBATripDetailsV2 *tripDetails;
@property(nonatomic,strong) OBAClassicDepartureView *tableHeaderView;
@property(nonatomic,strong) NSTimer *refreshTimer;
@property(nonatomic,strong) UIRefreshControl *refreshControl;
@property(nonatomic,strong) NSLock *reloadLock;
@end

// TODO: lots of this is duplicated from OBAStopViewController.
// Time to start considering how exactly it gets DRY'd up.

@implementation OBAArrivalAndDepartureViewController

- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    self = [super init];

    if (self) {
        _reloadLock = [[NSLock alloc] init];
        _arrivalAndDeparture = arrivalAndDeparture;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map"] style:UIBarButtonItemStylePlain target:self action:@selector(showMap:)];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadData:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

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

#pragma mark - Data Loading

- (void)reloadDataAnimated:(BOOL)animated {
    // If we're already loading data, then just bail.
    if (![self.reloadLock tryLock]) {
        return;
    }

    if (animated) {
        [self.refreshControl beginRefreshing];
    }

    [[OBAApplication sharedApplication].modelService requestArrivalAndDeparture:self.arrivalAndDeparture.instance].then(^(OBAArrivalAndDepartureV2 *arrivalAndDeparture) {
        self.arrivalAndDeparture = arrivalAndDeparture;
        return [[OBAApplication sharedApplication].modelService requestTripDetailsForTripInstance:self.arrivalAndDeparture.tripInstance];
    }).then(^(OBATripDetailsV2 *tripDetails) {
        self.tripDetails = tripDetails;
        [self populateTableWithArrivalAndDeparture:self.arrivalAndDeparture tripDetails:self.tripDetails];
    }).catch(^(NSError *error) {
        // TODO: handle error.
    }).finally(^{
        if (animated) {
            [self.refreshControl endRefreshing];
        }
        [self.reloadLock unlock];
    });
}

- (void)populateTableWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture tripDetails:(OBATripDetailsV2*)tripDetails {

    NSMutableArray *sections = [[NSMutableArray alloc] init];

    OBATableSection *serviceAlertsSection = [self.class createServiceAlertsSection:arrivalAndDeparture navigationController:self.navigationController];
    if (serviceAlertsSection) {
        [sections addObject:serviceAlertsSection];
    }

    NSArray<OBATableSection*> *tripDetailsSections = [self createTripDetailsSectionsWithArrivalAndDeparture:arrivalAndDeparture tripDetails:tripDetails];
    if (tripDetailsSections.count > 0) {
        [sections addObjectsFromArray:tripDetailsSections];
    }

    [sections addObject:[self.class createActionsSection:arrivalAndDeparture navigationController:self.navigationController]];

    self.sections = sections;
    [self.tableView reloadData];

    // Scroll the user's current stop to the top of the list
    NSUInteger index = [OBATripScheduleSectionBuilder indexOfStopID:arrivalAndDeparture.stopId inSchedule:tripDetails.schedule];
    if (index != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

#pragma mark - Section/Row Construction

+ (nullable OBATableSection*)createServiceAlertsSection:(OBAArrivalAndDepartureV2*)arrivalAndDeparture navigationController:(UINavigationController*)navigationController {
    OBAServiceAlertsModel* serviceAlerts = [[OBAApplication sharedApplication].modelDao getServiceAlertsModelForSituations:arrivalAndDeparture.situations];

    if (serviceAlerts.totalCount == 0) {
        return nil;
    }

    return [self createServiceAlertsSection:arrivalAndDeparture serviceAlerts:serviceAlerts navigationController:navigationController];
}

- (NSArray<OBATableSection*>*)createTripDetailsSectionsWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture tripDetails:(OBATripDetailsV2*)tripDetails {

    OBATableSection *stopsSection = [OBATripScheduleSectionBuilder buildStopsSection:tripDetails navigationController:self.navigationController];

    self.tableHeaderView = [self buildTableHeaderViewWithArrivalAndDeparture:arrivalAndDeparture];
    stopsSection.headerView = [self buildTableHeaderWrapperView:self.tableHeaderView];

    OBATableSection *connectionsSection = [OBATripScheduleSectionBuilder buildConnectionsSectionWithTripDetails:tripDetails tripInstance:arrivalAndDeparture.tripInstance navigationController:self.navigationController];

    return connectionsSection ? @[stopsSection, connectionsSection] : @[stopsSection];
}

- (OBAClassicDepartureView*)buildTableHeaderViewWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    OBAClassicDepartureView *tableHeaderView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
    tableHeaderView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    tableHeaderView.classicDepartureRow = [OBAArrivalAndDepartureSectionBuilder createDepartureRow:arrivalAndDeparture];

    return tableHeaderView;
}

- (UIView*)buildTableHeaderWrapperView:(UIView*)tableHeaderView {
    UIView *headerWrapperView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 60)];
    headerWrapperView.backgroundColor = [UIColor whiteColor];
    headerWrapperView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;

    tableHeaderView.frame = CGRectInset(headerWrapperView.bounds, [OBATheme defaultPadding], 0);
    [headerWrapperView addSubview:self.tableHeaderView];

    return headerWrapperView;
}

+ (OBATableSection*)createActionsSection:(OBAArrivalAndDepartureV2*)arrivalAndDeparture navigationController:(UINavigationController*)navigationController {
    OBATableSection *actionsSection = [[OBATableSection alloc] init];
    actionsSection.headerView = [OBASeparatorSectionView new];

    [actionsSection addRowWithBlock:^OBABaseRow * {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Report a problem for this trip", @"") action:^{
            OBAReportProblemWithTripViewController *vc = [[OBAReportProblemWithTripViewController alloc] initWithTripInstance:arrivalAndDeparture.tripInstance trip:arrivalAndDeparture.trip];
            vc.currentStopId = arrivalAndDeparture.stopId;
            [navigationController pushViewController:vc animated:YES];
        }];
        return tableRow;
    }];

    [actionsSection addRowWithBlock:^OBABaseRow * {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Vehicle Info", @"") action:^{
            OBAVehicleDetailsController *vc = [[OBAVehicleDetailsController alloc] initWithVehicleId:arrivalAndDeparture.tripStatus.vehicleId];
            [navigationController pushViewController:vc animated:YES];
        }];
        return tableRow;
    }];

    return actionsSection;
}

@end
