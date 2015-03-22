#import "OBAReportProblemWithTripViewController.h"
#import "OBALabelAndSwitchTableViewCell.h"
#import "OBALabelAndTextFieldTableViewCell.h"
#import "OBALogger.h"
#import "UITableViewController+oba_Additions.h"
#import "OBAStopViewController.h"
#import "OBAArrivalAndDepartureViewController.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"
//#import "OBAReport.h"

typedef NS_ENUM(NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeProblem,
    OBASectionTypeComment,
    OBASectionTypeOnTheVehicle,
    OBASectionTypeSubmit,
    OBASectionTypeNotes
};


@interface OBAReportProblemWithTripViewController (Private)

- (void)addProblemWithId:(NSString *)problemId name:(NSString *)problemName;

- (OBASectionType)sectionTypeForSection:(NSUInteger)section;
- (NSUInteger)sectionIndexForType:(OBASectionType)type;

- (UITableViewCell *)tableView:(UITableView *)tableView vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)getVehicleTypeLabeForTrip:(OBATripV2 *)trip;

- (void)submit;
- (void)showErrorAlert;
@end


@implementation OBAReportProblemWithTripViewController

#pragma mark -
#pragma mark Initialization

- (id)initWithApplicationDelegate:(OBAApplicationDelegate *)appDelegate tripInstance:(OBATripInstanceRef *)tripInstance trip:(OBATripV2 *)trip {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _appDelegate = appDelegate;
        _tripInstance = tripInstance;
        _trip = trip;

        self.navigationItem.title = NSLocalizedString(@"Report a Problem", @"self.navigationItem.title");

        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Custom Title", @"initWithTitle")
                                                                 style:UIBarButtonItemStyleBordered
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

        _activityIndicatorView = [[OBAModalActivityIndicator alloc] init];
    }

    return self;
}

#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.backBarButtonItem.title = NSLocalizedString(@"Problem", @"self.navigationItem.backBarButtonItem.title");
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self hideEmptySeparators];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [OBAAnalytics reportScreenView:[NSString stringWithFormat:@"View: %@", [self class]]];
}

#pragma mark Table view methods

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
    title.font = [UIFont systemFontOfSize:18];
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
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = [UIFont systemFontOfSize:18];
            cell.textLabel.text = _problemNames[_problemIndex];
            return cell;
        }

        case OBASectionTypeComment: {
            UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.font = [UIFont systemFontOfSize:18];

            if (_comment && [_comment length] > 0) {
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
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.font = [UIFont systemFontOfSize:18];
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
            OBATextEditViewController *vc = [OBATextEditViewController pushOntoViewController:self withText:_comment withTitle:NSLocalizedString(@"Comment", @"withTitle")];
            vc.delegate = self;
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

#pragma mark UITextFieldDelegate

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

#pragma mark Other methods

- (void)checkItemWithIndex:(NSIndexPath *)indexPath {
    _problemIndex = indexPath.row;
    NSUInteger section = [self sectionIndexForType:OBASectionTypeProblem];
    NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    [self.tableView reloadRowsAtIndexPaths:@[reloadIndexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark OBATextEditViewControllerDelegate

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

@end


@implementation OBAReportProblemWithTripViewController (Private)

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
            cell.label.font = [UIFont systemFontOfSize:18];
            [cell.toggleSwitch setOn:_onVehicle];
            [cell.toggleSwitch addTarget:self action:@selector(setOnVehicle:) forControlEvents:UIControlEventValueChanged];
            return cell;
        }

        case 1: {
            OBALabelAndTextFieldTableViewCell *cell = [OBALabelAndTextFieldTableViewCell getOrCreateCellForTableView:tableView];
            cell.label.text = [NSString stringWithFormat:@"%@ %@", [_vehicleType capitalizedString], NSLocalizedString(@"Number", @"cell.label.text")];
            cell.label.font = [UIFont systemFontOfSize:18];
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

    switch ([route.routeType intValue]) {
        case 0:
        case 1:
            return NSLocalizedString(@"metro", @"routeType 1");

        case 2:
            return NSLocalizedString(@"train", @"routeType 2");

        case 3:
            return NSLocalizedString(@"bus", @"routeType 3");

        case 4:
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
    problem.userLocation = _appDelegate.locationManager.currentLocation;

    [_activityIndicatorView show:self.view];
    [_appDelegate.modelService
     reportProblemWithTrip:problem
           completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
               if (error || !jsonData) {
               [self showErrorAlert];
               [self->_activityIndicatorView hide];
               }
               else {
               UIAlertView *view = [[UIAlertView alloc] init];
               view.title = NSLocalizedString(@"Submission Successful", @"view.title");
               [OBAAnalytics reportEventWithCategory:@"submit"
                                           action:@"report_problem"
                                            label:@"Reported Problem"
                                            value:nil];

               view.message = NSLocalizedString(@"The problem was sucessfully reported. Thank you!", @"view.message");
               [view addButtonWithTitle:NSLocalizedString(@"Dismiss", @"view addButtonWithTitle")];
               view.cancelButtonIndex = 0;
               [view show];
               [self->_activityIndicatorView hide];

               //go back to view that initiated report
               NSArray *allViewControllers = self.navigationController.viewControllers;

               for (NSInteger i = [allViewControllers count] - 1; i >= 0; i--) {
                id obj = [allViewControllers objectAtIndex:i];

                if ([obj isKindOfClass:[OBAArrivalAndDepartureViewController class]]) {
                    [self.navigationController
                     popToViewController:obj
                                animated:YES];
                    return;
                }
                else if ([obj isKindOfClass:[OBAStopViewController class]]) {
                    [self.navigationController
                     popToViewController:obj
                                animated:YES];
                    return;
                }
               }
               }
           }];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) [_appDelegate navigateToTarget:[OBANavigationTarget target:OBANavigationTargetTypeContactUs]];
}

- (void)showErrorAlert {
    UIAlertView *view = [[UIAlertView alloc] init];

    view.title = NSLocalizedString(@"Error Submitting", @"view.title");
    view.message = NSLocalizedString(@"An error occurred while reporting the problem. Please contact us directly.", @"view.message");
    view.delegate = self;
    [view addButtonWithTitle:NSLocalizedString(@"Contact Us", @"view addButtonWithTitle")];
    [view addButtonWithTitle:NSLocalizedString(@"Dismiss", @"view addButtonWithTitle")];
    view.cancelButtonIndex = 1;
    [view show];
}

@end