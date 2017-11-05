/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAReportProblemWithTripViewController.h"
#import "OBALabelAndSwitchTableViewCell.h"
#import "OBALabelAndTextFieldTableViewCell.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"
#import "OBAApplicationDelegate.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "OBAArrivalAndDepartureViewController.h"
@import OBAKit;

typedef NS_ENUM (NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeProblem,
    OBASectionTypeComment,
    OBASectionTypeOnTheVehicle,
    OBASectionTypeSubmit,
    OBASectionTypeNotes
};

@implementation OBAReportProblemWithTripViewController {
    OBATripInstanceRef *_tripInstance;
    OBATripV2 *_trip;
    NSMutableArray *_problemIds;
    NSMutableArray *_problemNames;
    NSUInteger _problemIndex;
    NSString *_comment;
    BOOL _onVehicle;
    NSString *_vehicleNumber;
    NSString *_vehicleType;
}

#pragma mark - Initialization

- (instancetype)initWithTripInstance:(OBATripInstanceRef *)tripInstance trip:(OBATripV2 *)trip {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _tripInstance = tripInstance;
        _trip = trip;

        self.navigationItem.title = NSLocalizedString(@"msg_report_a_problem", @"self.navigationItem.title");

        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"msg_custom_title", @"initWithTitle")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
        self.navigationItem.backBarButtonItem = item;



        _vehicleNumber = @"0000";
        _vehicleType = [self getVehicleTypeLabeForTrip:trip];

        _problemIds = [[NSMutableArray alloc] init];
        _problemNames = [[NSMutableArray alloc] init];

        [self addProblemWithId:@"vehicle_never_came" name:[NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"msg_the", @"name"), _vehicleType, NSLocalizedString(@"msg_never_came", @"name")]];
        [self addProblemWithId:@"vehicle_came_early" name:NSLocalizedString(@"msg_it_came_earlier_than_predicted", @"name")];
        [self addProblemWithId:@"vehicle_came_late" name:NSLocalizedString(@"msg_it_came_later_than_predicted", @"name")];
        [self addProblemWithId:@"wrong_headsign" name:NSLocalizedString(@"msg_wrong_destination_shown", @"name")];
        [self addProblemWithId:@"vehicle_does_not_stop_here" name:[NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"msg_the", @"name"), _vehicleType, NSLocalizedString(@"msg_doesnt_stop_here", @"name")]];
        [self addProblemWithId:@"other" name:NSLocalizedString(@"msg_other", @"name")];
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"msg_problem", @"self.navigationItem.backBarButtonItem.title");
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tableFooterView = [UIView new];
}

#pragma mark - Lazily Loaded Properties

- (OBALocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager = [OBAApplication sharedApplication].locationManager;
    }
    return _locationManager;
}

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeSubmit:
            return 70;

        default:
            return 40;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];

    view.backgroundColor = [OBATheme OBAGreenBackground];
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 290, 30)];
    title.font = [OBATheme bodyFont];
    title.backgroundColor = [UIColor clearColor];
    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeProblem:
            title.text = NSLocalizedString(@"msg_ask_whats_the_problem", @"OBASectionTypeProblem");
            break;

        case OBASectionTypeComment:
            title.text = NSLocalizedString(@"msg_optional_comment", @"OBASectionTypeComment");
            break;

        case OBASectionTypeOnTheVehicle:
            title.text = [NSString stringWithFormat:@"%@ %@?", NSLocalizedString(@"msg_optional_are_you_on_this", @"OBASectionTypeOnTheVehicle"), _vehicleType];
            break;

        case OBASectionTypeSubmit:
            view.frame = CGRectMake(0, 0, 320, 70);
            title.numberOfLines = 2;
            title.frame = CGRectMake(15, 5, 290, 60);
            title.text = NSLocalizedString(@"msg_explanatory_send_reports", @"OBASectionTypeNotes");
            break;

        default:
            break;
    }
    [view addSubview:title];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeProblem:
            return 1;

        case OBASectionTypeComment:
            return 1;

        case OBASectionTypeOnTheVehicle:
            return 2;

        case OBASectionTypeSubmit:
            return 1;

        case OBASectionTypeNotes:
            return 0;

        case OBASectionTypeNone:
        default:
            return 0;
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeProblem: {
            UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"identifier"];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = [OBATheme bodyFont];
            cell.textLabel.text = _problemNames[_problemIndex];
            return cell;
        }

        case OBASectionTypeComment: {
            UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"identifier"];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = [OBATheme bodyFont];

            if (_comment.length > 0) {
                cell.textLabel.textColor = [UIColor blackColor];
                cell.textLabel.text = _comment;
            }
            else {
                cell.textLabel.textColor = [UIColor grayColor];
                cell.textLabel.text = NSLocalizedString(@"msg_touch_to_edit", @"cell.textLabel.text");
            }

            return cell;
        }

        case OBASectionTypeOnTheVehicle:
            return [self tableView:tableView vehicleCellForRowAtIndexPath:indexPath];

        case OBASectionTypeSubmit: {
            UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"identifier"];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.font = [OBATheme bodyFont];
            cell.textLabel.text = NSLocalizedString(@"msg_submit", @"cell.textLabel.text");
            return cell;
        }

        default:
            break;
    }

    return [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"identifier"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeProblem: {
            NSIndexPath *selectedIndex = [NSIndexPath indexPathForRow:_problemIndex inSection:0];
            OBAListSelectionViewController *vc = [[OBAListSelectionViewController alloc] initWithValues:_problemNames selectedIndex:selectedIndex];
            vc.title = NSLocalizedString(@"msg_ask_whats_the_problem", @"vc.title");
            vc.delegate = self;
            vc.exitOnSelection = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }

        case OBASectionTypeComment: {
            OBATextEditViewController *vc = [[OBATextEditViewController alloc] init];
            vc.delegate = self;
            vc.text = _comment;
            vc.title = NSLocalizedString(@"msg_comment", @"withTitle");

            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:nil];

            break;
        }

        case OBASectionTypeSubmit: {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self submit];
        }

        default:
            break;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.placeholder = textField.text;
    textField.text = @"";
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.text.length == 0) {
        textField.text = textField.placeholder;
    }

    textField.placeholder = @"";
}

#pragma mark - Other methods

- (void)checkItemWithIndex:(NSIndexPath *)indexPath {
    _problemIndex = indexPath.row;
    NSUInteger section = [self sectionIndexForType:OBASectionTypeProblem];
    NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    [self.tableView reloadRowsAtIndexPaths:@[reloadIndexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - OBATextEditViewControllerDelegate

- (void)saveText:(NSString *)text {
    _comment = text;
    NSUInteger section = [self sectionIndexForType:OBASectionTypeComment];
    NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    [self.tableView reloadRowsAtIndexPaths:@[reloadIndexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)setOnVehicle:(id)obj {
    UISwitch *toggleSwitch = obj;

    _onVehicle = toggleSwitch.on;
}

- (void)setVehicleNumber:(id)obj {
    UITextField *textField = obj;

    _vehicleNumber = textField.text;
}

#pragma mark - Private

- (void)addProblemWithId:(NSString *)problemId name:(NSString *)problemName {
    [_problemIds addObject:problemId];
    [_problemNames addObject:problemName];
}

- (OBASectionType)sectionTypeForSection:(NSUInteger)section {
    switch (section) {
        case 0:
            return OBASectionTypeProblem;

        case 1:
            return OBASectionTypeComment;

        case 2:
            return OBASectionTypeOnTheVehicle;

        case 3:
            return OBASectionTypeSubmit;

        case 4:
            return OBASectionTypeNotes;

        default:
            return OBASectionTypeNone;
    }
}

- (NSUInteger)sectionIndexForType:(OBASectionType)type {
    switch (type) {
        case OBASectionTypeProblem:
            return 0;

        case OBASectionTypeComment:
            return 1;

        case OBASectionTypeOnTheVehicle:
            return 2;

        case OBASectionTypeSubmit:
            return 3;

        case OBASectionTypeNotes:
            return 4;

        case OBASectionTypeNone:
        default:
            break;
    }
    return -1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            OBALabelAndSwitchTableViewCell *cell = [OBALabelAndSwitchTableViewCell getOrCreateCellForTableView:tableView];
            cell.label.text = [NSString stringWithFormat:@"%@ %@?", NSLocalizedString(@"msg_on_this", @"cell.label.text"), [_vehicleType capitalizedString]];
            cell.label.font = [OBATheme bodyFont];
            [cell.toggleSwitch setOn:_onVehicle];
            [cell.toggleSwitch addTarget:self action:@selector(setOnVehicle:) forControlEvents:UIControlEventValueChanged];
            return cell;
        }

        case 1: {
            OBALabelAndTextFieldTableViewCell *cell = [OBALabelAndTextFieldTableViewCell getOrCreateCellForTableView:tableView];
            cell.label.text = [NSString stringWithFormat:@"%@ %@", [_vehicleType capitalizedString], NSLocalizedString(@"msg_number", @"cell.label.text")];
            cell.label.font = [OBATheme bodyFont];
            cell.textField.text = _vehicleNumber;
            cell.textField.delegate = self;
            [cell.textField addTarget:self action:@selector(setVehicleNumber:) forControlEvents:UIControlEventEditingChanged];
            [cell setNeedsLayout];
            return cell;
        }

        default:
            break;
    }

    return [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"identifier"];
}

- (NSString *)getVehicleTypeLabeForTrip:(OBATripV2 *)trip {
    OBARouteV2 *route = trip.route;
    // TODO: The value for light rail seems totally wrong.
    // And what does "metro" even mean?
    switch (route.routeType.unsignedIntegerValue) {
        case OBARouteTypeLightRail:
        case OBARouteTypeMetro:
            return NSLocalizedString(@"msg_metro", @"routeType 1");

        case OBARouteTypeTrain:
            return NSLocalizedString(@"msg_train", @"routeType 2");

        case OBARouteTypeBus:
            return NSLocalizedString(@"msg_bus", @"routeType 3");

        case OBARouteTypeFerry:
            return NSLocalizedString(@"msg_ferry", @"routeType 4");

        default:
            return NSLocalizedString(@"msg_vehicle", @"routeType default");
    }
}

- (void)submit {
    OBAReportProblemWithTripV2 *problem = [[OBAReportProblemWithTripV2 alloc] init];

    problem.tripInstance = _tripInstance;
    problem.stopId = self.currentStopId;
    problem.code = _problemIds[_problemIndex];
    problem.userComment = _comment;
    problem.userOnVehicle = _onVehicle;
    problem.userVehicleNumber = _vehicleNumber;
    problem.userLocation = self.locationManager.currentLocation;

    [SVProgressHUD show];
    [self.modelService reportProblemWithTrip:problem completionBlock:^(id jsonData, NSHTTPURLResponse *response, NSError *error) {
        [SVProgressHUD dismiss];

        if (error || !jsonData) {
            [self showErrorAlert];
            return;
        }

        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategorySubmit action:@"report_problem" label:@"Reported Problem" value:nil];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_submission_successful", @"view.title")
                                                                       message:NSLocalizedString(@"msg_sucessfull_report_send", @"view.message")
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            //go back to view that initiated report
            NSArray *allViewControllers = self.navigationController.viewControllers;
            for (UIViewController* vc in allViewControllers.reverseObjectEnumerator) {
                if ([vc isKindOfClass:[OBAArrivalAndDepartureViewController class]]) {
                    [self.navigationController popToViewController:vc animated:YES];
                    break;
                }
            }
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)showErrorAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_error_submitting", @"view.title") message:NSLocalizedString(@"msg_error_reporting_problem", @"view.message") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_contact_us", @"view addButtonWithTitle") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [APP_DELEGATE navigateToTarget:[OBANavigationTarget navigationTarget:OBANavigationTargetTypeContactUs]];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
