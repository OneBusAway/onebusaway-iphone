#import "OBAArrivalAndDepartureViewController.h"
#import "OBATripScheduleMapViewController.h"
#import "OBATripScheduleListViewController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBASituationsViewController.h"
#import "OBAVehicleDetailsController.h"
#import "OBALogger.h"
#import "OBAPresentation.h"
#import "OBAAnalytics.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBASubmitReportViewController.h"

typedef NS_ENUM(NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeTitle,
    OBASectionTypeServiceAlerts,
    OBASectionTypeSchedule,
    OBASectionTypeActions
};


@interface OBAArrivalAndDepartureViewController ()


@property (nonatomic, strong) OBAArrivalAndDepartureInstanceRef *instance;
@property (nonatomic, strong) OBAArrivalAndDepartureV2 *arrivalAndDeparture;
@property (nonatomic, strong) OBAArrivalEntryTableViewCellFactory *arrivalCellFactory;
@property (nonatomic, strong) OBAServiceAlertsModel *serviceAlerts;

@end


@implementation OBAArrivalAndDepartureViewController

- (id)initWithApplicationDelegate:(OBAApplicationDelegate *)appDelegate arrivalAndDepartureInstance:(OBAArrivalAndDepartureInstanceRef *)instance {
    if (self = [super initWithApplicationDelegate:appDelegate]) {
        _instance = instance;
        _arrivalAndDeparture = nil;
        _arrivalCellFactory = [[OBAArrivalEntryTableViewCellFactory alloc] initWithappDelegate:appDelegate tableView:self.tableView];
        _arrivalCellFactory.showServiceAlerts = NO;
        self.refreshable = YES;
        self.refreshInterval = 30;
        self.showUpdateTime = YES;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [OBAAnalytics reportScreenView:[NSString stringWithFormat:@"View: %@", [self class]]];
}

- (id)initWithApplicationDelegate:(OBAApplicationDelegate *)appDelegate arrivalAndDeparture:(OBAArrivalAndDepartureV2 *)arrivalAndDeparture {
    self = [self initWithApplicationDelegate:appDelegate arrivalAndDepartureInstance:arrivalAndDeparture.instance];
    _arrivalAndDeparture = arrivalAndDeparture;
    return self;
}

- (BOOL)isLoading {
    return _arrivalAndDeparture == nil;
}

- (id<OBAModelServiceRequest>)handleRefresh {
    return [self.appDelegate.modelService
            requestArrivalAndDepartureForStop:_instance
                              completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
                                  if (error) {
                                  [self refreshFailedWithError:error];
                                  }
                                  else {
                                  OBAEntryWithReferencesV2 *entry = jsonData;
                                  self.arrivalAndDeparture = entry.entry;

                                  OBAModelDAO *modelDao = self.appDelegate.modelDao;
                                  self.serviceAlerts = [modelDao getServiceAlertsModelForSituations:self->_arrivalAndDeparture.situations];
                                  [self refreshCompleteWithCode:responseCode];
                                      
                                  }
                              }];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self isLoading]) return [super numberOfSectionsInTableView:tableView];

    int count = 4; //3

    if (_serviceAlerts.unreadCount > 0) count++;

    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isLoading]) return [super tableView:tableView numberOfRowsInSection:section];

    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeTitle:
            return 1;

        case OBASectionTypeServiceAlerts:
            return 1;

        case OBASectionTypeSchedule:
            return 2;

        case OBASectionTypeActions: {
            int count = 3;

            if (_arrivalAndDeparture.tripStatus.vehicleId && ![_arrivalAndDeparture.tripStatus.vehicleId isEqualToString:@""]) count++;

            return count;
        }

        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLoading]) return [super tableView:tableView cellForRowAtIndexPath:indexPath];

    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeTitle:
            return [self titleCellForRowAtIndexPath:indexPath tableView:tableView];

        case OBASectionTypeServiceAlerts:
            return [self serviceAlertsCellForRowAtIndexPath:indexPath tableView:tableView];

        case OBASectionTypeSchedule:
            return [self scheduleCellForRowAtIndexPath:indexPath tableView:tableView];

        case OBASectionTypeActions:
            return [self actionCellForRowAtIndexPath:indexPath tableView:tableView];

        default:
            break;
    }

    return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLoading]) {
        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
        return;
    }

    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeServiceAlerts:
            [self didSelectServiceAlertRowAtIndexPath:indexPath tableView:tableView];
            break;

        case OBASectionTypeSchedule:
            [self didSelectScheduleRowAtIndexPath:indexPath tableView:tableView];
            break;

        case OBASectionTypeActions:
            [self didSelectActionRowAtIndexPath:indexPath tableView:tableView];
            break;

        default:
            break;
    }
}

- (OBASectionType)sectionTypeForSection:(NSUInteger)section {
    NSUInteger offset = 0;

    if (offset == section) return OBASectionTypeTitle;

    offset++;

    if (_serviceAlerts.unreadCount > 0) {
        if (offset == section) return OBASectionTypeServiceAlerts;

        offset++;
    }

    if (offset == section) return OBASectionTypeSchedule;

    offset++;

    if (offset == section) return OBASectionTypeActions;

    return OBASectionTypeNone;
}

- (UITableViewCell *)titleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    OBAArrivalEntryTableViewCell *cell = [_arrivalCellFactory createCellForArrivalAndDeparture:_arrivalAndDeparture];

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.alertLabel.text = @"";
    return cell;
}

- (UITableViewCell *)serviceAlertsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    return [UITableViewCell tableViewCellForUnreadServiceAlerts:_serviceAlerts tableView:tableView];
}

- (UITableViewCell *)scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];

    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Show as map", @"text");
            break;

        case 1:
            cell.textLabel.text = NSLocalizedString(@"Show as list", @"text");
            break;
    }

    return cell;
}

- (UITableViewCell *)actionCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    switch (indexPath.row) {
        case 0: {
          UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
          cell.selectionStyle = UITableViewCellSelectionStyleBlue;
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          cell.textLabel.textColor = [UIColor blackColor];
          cell.textLabel.textAlignment = NSTextAlignmentLeft;
          cell.textLabel.font = [UIFont systemFontOfSize:18];
          cell.textLabel.text = NSLocalizedString(@"Bus is FULL", @"text");
          return cell;
        }
        
        case 1: {
            return [UITableViewCell tableViewCellForServiceAlerts:_serviceAlerts tableView:tableView];
        }

        case 2: {
            UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.textLabel.text = NSLocalizedString(@"Report a problem for this trip", @"text");
            return cell;
        }

        case 3: {
            UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.textColor = [UIColor blackColor];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.textLabel.text = NSLocalizedString(@"Vehicle Info", @"cell.textLabel.text");
            return cell;
        }

        default:
            break;
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self sectionTypeForSection:indexPath.section] == OBASectionTypeTitle) {
        return 50;
    }

    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch ([self sectionTypeForSection:section]) {
        case OBASectionTypeSchedule:
            return 40;

        case OBASectionTypeActions:
            return 30;

        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];

    view.backgroundColor = OBAGREENBACKGROUND;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 30)];
    title.font = [UIFont systemFontOfSize:18];
    title.backgroundColor = [UIColor clearColor];



    switch ([self sectionTypeForSection:section]) {
        case OBASectionTypeSchedule:
            title.text = NSLocalizedString(@"Trip Details", @"OBASectionTypeSchedule");
            break;

        case OBASectionTypeActions:
            //title.text = NSLocalizedString(@"Actions",@"OBASectionTypeActions");
            break;

        default:
            break;
    }
    [view addSubview:title];

    return view;
}

- (void)didSelectServiceAlertRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    [self showSituations];
}

- (void)didSelectScheduleRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    OBATripInstanceRef *tripInstance = _arrivalAndDeparture.tripInstance;

    if (indexPath.row == 0) {
        OBATripScheduleMapViewController *vc = [[OBATripScheduleMapViewController alloc] initWithApplicationDelegate:self.appDelegate];
        vc.tripInstance = tripInstance;
        vc.currentStopId = _arrivalAndDeparture.stopId;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.row == 1) {
        OBATripScheduleListViewController *vc = [[OBATripScheduleListViewController alloc] initWithApplicationDelegate:self.appDelegate tripInstance:tripInstance];
        vc.currentStopId = _arrivalAndDeparture.stopId;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    switch (indexPath.row) {
        case 0: {
          OBASubmitReportViewController *vc = [[OBASubmitReportViewController alloc] initWithNibName:@"OBASubmitReportViewController" bundle:[NSBundle mainBundle]];
          vc.selectedArrivalAndDeparture = _arrivalAndDeparture;
          [self.navigationController pushViewController:vc animated:YES];
          break;
        }
        
        case 1: {
            [self showSituations];
            break;
        }

        case 2: {
            OBATripInstanceRef *tripInstance = _arrivalAndDeparture.tripInstance;
            OBAReportProblemWithTripViewController *vc = [[OBAReportProblemWithTripViewController alloc] initWithApplicationDelegate:self.appDelegate tripInstance:tripInstance trip:_arrivalAndDeparture.trip];
            vc.currentStopId = _arrivalAndDeparture.stopId;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }

        case 3: {
            OBAVehicleDetailsController *vc = [[OBAVehicleDetailsController alloc] initWithApplicationDelegate:self.appDelegate vehicleId:_arrivalAndDeparture.tripStatus.vehicleId];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
    }
}

- (void)showSituations {
    NSDictionary *args = @{ @"arrivalAndDeparture": _arrivalAndDeparture };

    [OBASituationsViewController showSituations:_arrivalAndDeparture.situations withappDelegate:self.appDelegate navigationController:self.navigationController args:args];
}

@end
