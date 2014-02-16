#import "OBATripDetailsViewController.h"
#import "OBATripScheduleMapViewController.h"
#import "OBATripScheduleListViewController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBALogger.h"
#import "OBAArrivalEntryTableViewCell.h"


typedef enum {
    OBASectionTypeNone,
    OBASectionTypeLoading,
    OBASectionTypeTitle,
    OBASectionTypeServiceAlerts,
    OBASectionTypeSchedule,
    OBASectionTypeActions
} OBASectionType;


@interface OBATripDetailsViewController (Private)

- (OBASectionType)sectionTypeForSection:(NSUInteger)section;

- (UITableViewCell *)tableView:(UITableView *)tableView titleCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)didSelectScheduleRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
- (void)didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end


@implementation OBATripDetailsViewController

- (id)initWithApplicationDelegate:(OBAApplicationDelegate *)appDelegate tripInstance:(OBATripInstanceRef *)tripInstance {
    if (self = [super initWithApplicationDelegate:appDelegate]) {
        _tripInstance = tripInstance;
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
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (BOOL)isLoading {
    return self.tripDetails == nil;
}

- (id<OBAModelServiceRequest>)handleRefresh {
    return [self.appDelegate.modelService requestTripDetailsForTripInstance:self.tripInstance withDelegate:self withContext:nil];
}

- (void)handleData:(id)obj context:(id)context {
    OBAEntryWithReferencesV2 *entry = obj;

    self.tripDetails = entry.entry;
}

- (void)handleDataChanged {
    self.serviceAlerts = [self.appDelegate.modelDao getServiceAlertsModelForSituations:self.tripDetails.situations];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self isLoading]) {
        return [super numberOfSectionsInTableView:tableView];
    }

    if (_tripDetails) return 3;

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isLoading]) {
        return [super tableView:tableView numberOfRowsInSection:section];
    }

    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeLoading:
            return 1;

        case OBASectionTypeTitle:
            return 1;

        case OBASectionTypeSchedule:
            return 2;

        case OBASectionTypeActions:
            return 1;

        case OBASectionTypeNone:
        default:
            return 0;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLoading]) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }

    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeTitle:
            return [self tableView:tableView titleCellForRowAtIndexPath:indexPath];

        case OBASectionTypeSchedule:
            return [self tableView:tableView scheduleCellForRowAtIndexPath:indexPath];

        case OBASectionTypeActions:
            return [self tableView:tableView actionCellForRowAtIndexPath:indexPath];

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
        case OBASectionTypeSchedule:
            [self didSelectScheduleRowAtIndexPath:indexPath tableView:tableView];
            break;

        case OBASectionTypeActions: {
            [self didSelectActionRowAtIndexPath:indexPath tableView:tableView];
            break;
        }

        default:
            break;
    }
}

@end


@implementation OBATripDetailsViewController (Private)

- (void)didSelectScheduleRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    if (indexPath.row == 0) {
        if (self.tripDetails) {
            OBATripScheduleMapViewController *vc = [[OBATripScheduleMapViewController alloc]initWithApplicationDelegate:self.appDelegate];
            vc.tripInstance = self.tripInstance;
            vc.tripDetails = self.tripDetails;
            vc.currentStopId = self.currentStopId;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else if (indexPath.row == 1) {
        if (self.tripDetails) {
            OBATripScheduleListViewController *vc = [[OBATripScheduleListViewController alloc] initWithApplicationDelegate:self.appDelegate tripInstance:self.tripInstance];
            vc.tripDetails = self.tripDetails;
            vc.currentStopId = self.currentStopId;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (void)didSelectActionRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    if (indexPath.row == 0) {
        if (self.tripDetails) {
            OBAReportProblemWithTripViewController *vc = [[OBAReportProblemWithTripViewController alloc] initWithApplicationDelegate:self.appDelegate tripInstance:self.tripInstance trip:self.tripDetails.trip];
            vc.currentStopId = self.currentStopId;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

- (OBASectionType)sectionTypeForSection:(NSUInteger)section {
    if (self.tripDetails) {
        switch (section) {
            case 0:

                return OBASectionTypeTitle;

            case 1:
                return OBASectionTypeSchedule;

            case 2:
                return OBASectionTypeActions;

            default:
                return OBASectionTypeNone;
        }
    }
    else {
        if (section == 0) return OBASectionTypeLoading;

        return OBASectionTypeNone;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView titleCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OBAArrivalEntryTableViewCell *cell = [OBAArrivalEntryTableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    OBATripV2 *trip = self.tripDetails.trip;
    
    NSString *routeName = trip.routeShortName;
    if (!routeName) {
        routeName = trip.route.safeShortName;
    }
    
    cell.routeLabel.text = routeName;
    cell.destinationLabel.text = trip.tripHeadsign ? trip.tripHeadsign : @"";
    cell.statusLabel.text = NSLocalizedString(@"Schedule data only", @"cell.detailTextLable.text");

    OBATripStatusV2 *status = self.tripDetails.status;

    if (status && status.predicted) {
        NSInteger scheduleDeviation = status.scheduleDeviation / 60;
        NSString *label = @"";

        if (scheduleDeviation <= -2) label = [NSString stringWithFormat:@"%d %@", (-scheduleDeviation), NSLocalizedString(@"minutes early", @"scheduleDeviation <= -2")];
        else if (scheduleDeviation < 2) label = NSLocalizedString(@"on time", @"scheduleDeviation < 2");
        else label = [NSString stringWithFormat:@"%d %@", scheduleDeviation, NSLocalizedString(@"minutes late", @"scheduleDeviation >= 2")];

        cell.statusLabel.text = [NSString stringWithFormat:@"%@ # %@ - %@", NSLocalizedString(@"Vehicle", @"cell.statusLabel.text"), status.vehicleId, label];
    }

    cell.minutesLabel.text = @"";
    cell.minutesSubLabel.text = @"";
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
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

- (UITableViewCell *)tableView:(UITableView *)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];


    switch (indexPath.row) {
        case 0: {
            cell.textLabel.text = NSLocalizedString(@"Report a problem for this trip", @"text");

            if (_tripDetails == nil) {
                cell.textLabel.textColor = [UIColor grayColor];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            else {
                cell.textLabel.textColor = [UIColor blackColor];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            }

            break;
        }
    }

    return cell;
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
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(11, 5, 200, 30)];
    title.font = [UIFont systemFontOfSize:18];
    title.backgroundColor = [UIColor clearColor];

    if ([self sectionTypeForSection:section] == OBASectionTypeSchedule) {
        title.text = NSLocalizedString(@"Trip Schedule:", @"OBASectionTypeSchedule");
    }

    [view addSubview:title];
    return view;
}

@end
