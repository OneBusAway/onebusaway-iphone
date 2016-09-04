#import "OBAVehicleDetailsController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBASituationsViewController.h"
#import "OBAAnalytics.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAApplication.h"
#import "OBACommonV1.h"

typedef NS_ENUM (NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeVehicleDetails,
    OBASectionTypeTripDetails
};

@interface OBAVehicleDetailsController ()

@property (nonatomic, strong) NSString *vehicleId;
@property (nonatomic, strong) OBAVehicleStatusV2 *vehicleStatus;

@end


@implementation OBAVehicleDetailsController

- (id)initWithVehicleId:(NSString *)vehicleId {
    if (self = [super init]) {
        _vehicleId = vehicleId;
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

- (BOOL)isLoading {
    return _vehicleStatus == nil;
}

- (id<OBAModelServiceRequest>)handleRefresh {
    @weakify(self);
    return [[OBAApplication sharedApplication].modelService
            requestVehicleForId:_vehicleId
                completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
                    @strongify(self);

                    if (error) {
                    [self refreshFailedWithError:error];
                    }
                    else {
                    OBAEntryWithReferencesV2 *entry = jsonData;
                    self.vehicleStatus = entry.entry;
                    [self refreshCompleteWithCode:responseCode];
                    }
                }];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self isLoading]) {
        return [super numberOfSectionsInTableView:tableView];
    }
    else {
        NSInteger count = 1;

        if (_vehicleStatus.tripStatus) {
            count += 2;
        }

        return count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isLoading]) return [super tableView:tableView numberOfRowsInSection:section];

    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeVehicleDetails:
            return 1;

        case OBASectionTypeTripDetails:
            return 2;

        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self isLoading]) return nil;

    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeVehicleDetails:
            return NSLocalizedString(@"Vehicle Details:", @"OBASectionTypeVehicleDetails");

        case OBASectionTypeTripDetails:
            return NSLocalizedString(@"Active Trip Details:", @"OBASectionTypeTripDetails");

        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLoading]) return [super tableView:tableView cellForRowAtIndexPath:indexPath];

    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeVehicleDetails:
            return [self vehicleCellForRowAtIndexPath:indexPath tableView:tableView];

        case OBASectionTypeTripDetails:
            return [self tripDetailsCellForRowAtIndexPath:indexPath tableView:tableView];

        default:
            break;
    }

    return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (OBASectionType)sectionTypeForSection:(NSUInteger)section {
    NSUInteger offset = 0;

    if (offset == section) return OBASectionTypeVehicleDetails;

    offset++;

    if (_vehicleStatus.tripStatus) {
        if (offset == section) return OBASectionTypeTripDetails;

        offset++;

    }

    return OBASectionTypeNone;
}

- (UITableViewCell *)vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Vehicle", @"cell.textLabel.text"), _vehicleStatus.vehicleId];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    NSString *result = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_vehicleStatus.lastUpdateTime / 1000.0]];

    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Last update", @"cell.detailTextLabel.text"), result];

    return cell;
}

- (UITableViewCell *)tripDetailsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    OBATripStatusV2 *tripStatus = _vehicleStatus.tripStatus;
    OBATripV2 *trip = tripStatus.activeTrip;

    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [OBATheme bodyFont];
    switch (indexPath.row) {
        case 0: {
            NSString *routeShortName = trip.route.shortName ? : trip.route.longName;
            NSString *tripHeadsign = trip.tripHeadsign;
            cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", routeShortName, tripHeadsign];
            break;
        }

        case 1: {
            if (tripStatus.frequency) {
                cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Schedule deviation", @"cell.textLabel.text"), NSLocalizedString(@"N/A", @"cell.textLabel.text")];
            }
            else {
                NSInteger sd = tripStatus.scheduleDeviation;
                NSString *label = @" ";

                if (sd > 0) {
                    label = NSLocalizedString(@" late", @"sd > 0");
                }
                else if (sd < 0) {
                    label = NSLocalizedString(@" early", @"sd < 0");
                    sd = -sd;
                }

                NSInteger mins = sd / 60;
                NSInteger secs = sd % 60;

                cell.textLabel.text = [NSString stringWithFormat:@"%@: %ldm %lds%@", NSLocalizedString(@"Schedule deviation", @"cell.textLabel.text"), (long)mins, (long)secs, label];
            }

            break;
        }
    }

    return cell;
}

- (UITableViewCell *)tripScheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [OBATheme bodyFont];
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Show as map", @"VehicleDetailsController");

            break;

        case 1:
            cell.textLabel.text = NSLocalizedString(@"Show as list", @"VehicleDetailsController");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
    }

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];

    view.backgroundColor = [OBATheme OBAGreenBackground];
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 30)];
    title.font = [OBATheme bodyFont];
    title.backgroundColor = [UIColor clearColor];
    OBASectionType sectionType = [self sectionTypeForSection:section];

    if (![self isLoading]) {
        switch (sectionType) {
            case OBASectionTypeVehicleDetails:
                title.text = NSLocalizedString(@"Vehicle Details:", @"OBASectionTypeVehicleDetails");
                break;

            case OBASectionTypeTripDetails:
                title.text = NSLocalizedString(@"Active Trip Details:", @"OBASectionTypeTripDetails");
                break;

            default:
                break;
        }
    }

    [view addSubview:title];
    return view;
}

@end
