#import "OBAReportProblemWithTripViewController.h"
#import "OBALabelAndSwitchTableViewCell.h"
#import "OBALabelAndTextFieldTableViewCell.h"
#import "OBALogger.h"
#import "UITableViewController+oba_Additions.h"
#import "OBAGenericStopViewController.h"
#import "OBAArrivalAndDepartureViewController.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"
#import "OBAApplicationDelegate.h"
#import <SVProgressHUD/SVProgressHUD.h>

typedef NS_ENUM (NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeProblem,
    OBASectionTypeComment,
    OBASectionTypeOnTheVehicle,
    OBASectionTypeSubmit,
    OBASectionTypeNotes
};


@interface OBAReportProblemWithTripViewController ()
@end


@implementation OBAReportProblemWithTripViewController

#pragma mark - Initialization

- (id)initWithTripInstance:(OBATripInstanceRef *)tripInstance trip:(OBATripV2 *)trip {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _tripInstance = tripInstance;
        _trip = trip;

        self.navigationItem.title = NSLocalizedString(@"Report a Problem", @"self.navigationItem.title");

        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Custom Title", @"initWithTitle")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
        self.navigationItem.backBarButtonItem = item;



        _vehicleNumber = @"0000";
        _vehicleType = [self getVehicleTypeLabeForTrip:trip];

        _problemIds = [[NSMutableArray alloc] init];
        _problemNames = [[NSMutableArray alloc] init];

        [self addProblemWithId:@"vehicle_never_came" name:[NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"The", @"name"), _vehicleType, NSLocalizedString(@"never came", @"name")]];
        [self addProblemWithId:@"vehicle_came_early" name:NSLocalizedString(@"It came earlier than predicted", @"name")];
        [self addProblemWithId:@"vehicle_came_late" name:NSLocalizedString(@"It came later than predicted", @"name")];
        [self addProblemWithId:@"wrong_headsign" name:NSLocalizedString(@"Wrong destination shown", @"name")];
        [self addProblemWithId:@"vehicle_does_not_stop_here" name:[NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"The", @"name"), _vehicleType, NSLocalizedString(@"doesn't stop here", @"name")]];
        [self addProblemWithId:@"other" name:NSLocalizedString(@"Other", @"name")];
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"Problem", @"self.navigationItem.backBarButtonItem.title");
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self hideEmptySeparators];
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

    view.backgroundColor = OBAGREENBACKGROUND;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 290, 30)];
    title.font = [OBATheme bodyFont];
    title.backgroundColor = [UIColor clearColor];
    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeProblem:
            title.text = NSLocalizedString(@"What's the problem?", @"OBASectionTypeProblem");
            break;

        case OBASectionTypeComment:
            title.text = NSLocalizedString(@"Optional - Comment:", @"OBASectionTypeComment");
            break;

        case OBASectionTypeOnTheVehicle:
            title.text = [NSString stringWithFormat:@"%@ %@?", NSLocalizedString(@"Optional - Are you on this", @"OBASectionTypeOnTheVehicle"), _vehicleType];
            break;

        case OBASectionTypeSubmit:
            view.frame = CGRectMake(0, 0, 320, 70);
            title.numberOfLines = 2;
            title.frame = CGRectMake(15, 5, 290, 60);
            title.text = NSLocalizedString(@"Your reports help OneBusAway find and fix problems with the system.", @"OBASectionTypeNotes");
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
            UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = [OBATheme bodyFont];
            cell.textLabel.text = _problemNames[_problemIndex];
            return cell;
        }

        case OBASectionTypeComment: {
            UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
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
                cell.textLabel.text = NSLocalizedString(@"Touch to edit", @"cell.textLabel.text");
            }

            return cell;
        }

        case OBASectionTypeOnTheVehicle:
            return [self tableView:tableView vehicleCellForRowAtIndexPath:indexPath];

        case OBASectionTypeSubmit: {
            UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.font = [OBATheme bodyFont];
            cell.textLabel.text = NSLocalizedString(@"Submit", @"cell.textLabel.text");
            return cell;
        }

        default:
            break;
    }

    return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeProblem: {
            NSIndexPath *selectedIndex = [NSIndexPath indexPathForRow:_problemIndex inSection:0];
            OBAListSelectionViewController *vc = [[OBAListSelectionViewController alloc] initWithValues:_problemNames selectedIndex:selectedIndex];
            vc.title = NSLocalizedString(@"What's the problem?", @"vc.title");
            vc.delegate = self;
            vc.exitOnSelection = YES;
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }

        case OBASectionTypeComment: {
            OBATextEditViewController *vc = [[OBATextEditViewController alloc] init];
            vc.delegate = self;
            vc.text = _comment;
            vc.title = NSLocalizedString(@"Comment", @"withTitle");

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
            cell.label.text = [NSString stringWithFormat:@"%@ %@?", NSLocalizedString(@"On this", @"cell.label.text"), [_vehicleType capitalizedString]];
            cell.label.font = [OBATheme bodyFont];
            [cell.toggleSwitch setOn:_onVehicle];
            [cell.toggleSwitch addTarget:self action:@selector(setOnVehicle:) forControlEvents:UIControlEventValueChanged];
            return cell;
        }

        case 1: {
            OBALabelAndTextFieldTableViewCell *cell = [OBALabelAndTextFieldTableViewCell getOrCreateCellForTableView:tableView];
            cell.label.text = [NSString stringWithFormat:@"%@ %@", [_vehicleType capitalizedString], NSLocalizedString(@"Number", @"cell.label.text")];
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

    return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (NSString *)getVehicleTypeLabeForTrip:(OBATripV2 *)trip {
    OBARouteV2 *route = trip.route;
    // TODO: The value for light rail seems totally wrong.
    // And what does "metro" even mean?
    switch (route.routeType.unsignedIntegerValue) {
        case OBARouteTypeLightRail:
        case OBARouteTypeMetro:
            return NSLocalizedString(@"metro", @"routeType 1");

        case OBARouteTypeTrain:
            return NSLocalizedString(@"train", @"routeType 2");

        case OBARouteTypeBus:
            return NSLocalizedString(@"bus", @"routeType 3");

        case OBARouteTypeFerry:
            return NSLocalizedString(@"ferry", @"routeType 4");

        default:
            return NSLocalizedString(@"vehicle", @"routeType default");
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
    problem.userLocation = [OBAApplication sharedApplication].locationManager.currentLocation;

    [SVProgressHUD show];
    [[OBAApplication sharedApplication].modelService reportProblemWithTrip:problem completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
        [SVProgressHUD dismiss];

        if (error || !jsonData) {
            [self showErrorAlert];
            return;
        }

        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategorySubmit action:@"report_problem" label:@"Reported Problem" value:nil];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Submission Successful", @"view.title")
                                                                       message:NSLocalizedString(@"The problem was sucessfully reported. Thank you!", @"view.message")
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            //go back to view that initiated report
            NSArray *allViewControllers = self.navigationController.viewControllers;
            for (UIViewController* vc in allViewControllers.reverseObjectEnumerator) {
                if ([vc isKindOfClass:[OBAArrivalAndDepartureViewController class]] || [vc isKindOfClass:[OBAArrivalAndDepartureViewController class]]) {
                    [self.navigationController popToViewController:vc animated:YES];
                    break;
                }
            }
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)showErrorAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error Submitting", @"view.title") message:NSLocalizedString(@"An error occurred while reporting the problem. Please contact us directly.", @"view.message") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", @"view addButtonWithTitle") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Contact Us", @"view addButtonWithTitle") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [APP_DELEGATE navigateToTarget:[OBANavigationTarget target:OBANavigationTargetTypeContactUs]];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end