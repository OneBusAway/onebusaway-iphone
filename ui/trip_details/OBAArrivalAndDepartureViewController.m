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
#import "OBATripScheduleListViewController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBAVehicleDetailsController.h"
#import "OBASeparatorSectionView.h"

static NSTimeInterval const kRefreshTimeInterval = 30;

@interface OBAArrivalAndDepartureViewController ()
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
        [self populateTableWithArrivalAndDeparture:self.arrivalAndDeparture];
    }).catch(^(NSError *error) {
        // handle error.
    }).finally(^{
        if (animated) {
            [self.refreshControl endRefreshing];
        }
        [self.reloadLock unlock];
    });
}

+ (OBATableSection*)createDepartureSection:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    NSString *dest = arrivalAndDeparture.tripHeadsign.capitalizedString;
    OBAClassicDepartureRow *departureRow = [[OBAClassicDepartureRow alloc] initWithRouteName:arrivalAndDeparture.bestAvailableName destination:dest departsAt:[NSDate dateWithTimeIntervalSince1970:(arrivalAndDeparture.bestDepartureTime / 1000)] statusText:[arrivalAndDeparture statusText] departureStatus:[arrivalAndDeparture departureStatus] action:nil];

    OBATableSection *departureSection = [[OBATableSection alloc] initWithTitle:nil rows:@[departureRow]];

    return departureSection;
}

+ (nullable OBATableSection*)createServiceAlertsSection:(OBAArrivalAndDepartureV2*)arrivalAndDeparture navigationController:(UINavigationController*)navigationController {
    OBAServiceAlertsModel* serviceAlerts = [[OBAApplication sharedApplication].modelDao getServiceAlertsModelForSituations:arrivalAndDeparture.situations];
    if (serviceAlerts.totalCount > 0) {
        return [self createServiceAlertsSection:arrivalAndDeparture serviceAlerts:serviceAlerts navigationController:navigationController];
    }
    else {
        return nil;
    }
}

+ (OBATableSection*)createTripDetailsSection:(OBAArrivalAndDepartureV2*)arrivalAndDeparture navigationController:(UINavigationController*)navigationController {
    OBATableSection *tripDetails = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Trip Details", @"OBASectionTypeSchedule")];

    [tripDetails addRow:^OBABaseRow * {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Show as Map", @"") action:^{
            OBATripScheduleMapViewController *vc = [[OBATripScheduleMapViewController alloc] init];
            vc.tripInstance = arrivalAndDeparture.tripInstance;
            vc.currentStopId = arrivalAndDeparture.stopId;
            [navigationController pushViewController:vc animated:YES];
        }];
        tableRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        return tableRow;
    }];

    [tripDetails addRow:^OBABaseRow * {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Show as List", @"") action:^{
            OBATripScheduleListViewController *vc = [[OBATripScheduleListViewController alloc] initWithTripInstance:arrivalAndDeparture.tripInstance];
            vc.currentStopId = arrivalAndDeparture.stopId;
            [navigationController pushViewController:vc animated:YES];
        }];
        tableRow.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        return tableRow;
    }];

    return tripDetails;
}

+ (OBATableSection*)createActionsSection:(OBAArrivalAndDepartureV2*)arrivalAndDeparture navigationController:(UINavigationController*)navigationController {
    OBATableSection *actionsSection = [[OBATableSection alloc] init];
    actionsSection.headerView = [OBASeparatorSectionView new];

    [actionsSection addRow:^OBABaseRow * {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Report a problem for this trip", @"") action:^{
            OBAReportProblemWithTripViewController *vc = [[OBAReportProblemWithTripViewController alloc] initWithTripInstance:arrivalAndDeparture.tripInstance trip:arrivalAndDeparture.trip];
            vc.currentStopId = arrivalAndDeparture.stopId;
            [navigationController pushViewController:vc animated:YES];
        }];
        return tableRow;
    }];

    [actionsSection addRow:^OBABaseRow * {
        OBATableRow *tableRow = [[OBATableRow alloc] initWithTitle:NSLocalizedString(@"Vehicle Info", @"") action:^{
            OBAVehicleDetailsController *vc = [[OBAVehicleDetailsController alloc] initWithVehicleId:arrivalAndDeparture.tripStatus.vehicleId];
            [navigationController pushViewController:vc animated:YES];
        }];
        return tableRow;
    }];

    return actionsSection;
}

- (void)populateTableWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {

    NSMutableArray *sections = [[NSMutableArray alloc] init];

    [sections addObject:[self.class createDepartureSection:arrivalAndDeparture]];

    OBATableSection *serviceAlertsSection = [self.class createServiceAlertsSection:arrivalAndDeparture navigationController:self.navigationController];
    if (serviceAlertsSection) {
        [sections addObject:serviceAlertsSection];
    }

    [sections addObject:[self.class createTripDetailsSection:arrivalAndDeparture navigationController:self.navigationController]];

    // Actions

    [sections addObject:[self.class createActionsSection:arrivalAndDeparture navigationController:self.navigationController]];

    self.sections = sections;
    [self.tableView reloadData];
}
@end
