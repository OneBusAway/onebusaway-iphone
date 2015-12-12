#import "OBAReportProblemWithStopViewController.h"
#import "OBALogger.h"
#import "UITableViewController+oba_Additions.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"

typedef NS_ENUM (NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeProblem,
    OBASectionTypeComment,
    OBASectionTypeSubmit,
    OBASectionTypeNotes
};


@interface OBAReportProblemWithStopViewController (Private)

- (void)addProblemWithId:(NSString *)problemId name:(NSString *)problemName;

- (OBASectionType)sectionTypeForSection:(NSUInteger)section;
- (NSUInteger)sectionIndexForType:(OBASectionType)type;

- (void)submit;
- (void)showErrorAlert;
@end


@implementation OBAReportProblemWithStopViewController

#pragma mark -
#pragma mark Initialization

- (id)initWithApplicationDelegate:(OBAApplicationDelegate *)context stop:(OBAStopV2 *)stop {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _appDelegate = context;
        _stop = stop;

        self.navigationItem.title = NSLocalizedString(@"Report a Problem", @"self.navigationItem.title");

        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Custom Title", @"UIBarButtonItem * item")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
        self.navigationItem.backBarButtonItem = item;

        _problemIds = [[NSMutableArray alloc] init];
        _problemNames = [[NSMutableArray alloc] init];

        [self addProblemWithId:@"stop_name_wrong" name:NSLocalizedString(@"Stop name is wrong", @"name")];
        [self addProblemWithId:@"stop_number_wrong" name:NSLocalizedString(@"Stop number is wrong", @"name")];
        [self addProblemWithId:@"stop_location_wrong" name:NSLocalizedString(@"Stop location is wrong", @"name")];
        [self addProblemWithId:@"route_or_trip_missing" name:NSLocalizedString(@"Route or scheduled trip is missing", @"name")];
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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeSubmit:
            return 70;

            break;

        case OBASectionTypeProblem:
        case OBASectionTypeComment:
        default:
            return 40;

            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];

    view.backgroundColor = OBAGREENBACKGROUND;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 30)];
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

        case OBASectionTypeSubmit:
            view.frame = CGRectMake(0, 0, 320, 70);
            title.numberOfLines = 2;
            title.frame = CGRectMake(15, 5, 290, 60);
            title.text = NSLocalizedString(@"Your reports help OneBusAway find and fix problems with the system.", @"OBASectionTypeSubmit");
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
            OBATextEditViewController *vc = [OBATextEditViewController pushOntoViewController:self withText:_comment withTitle:NSLocalizedString(@"Comment", @"OBATextEditViewController withTitle")];
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

#pragma mark OBAListSelectionViewController

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

@end


@implementation OBAReportProblemWithStopViewController (Private)

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
            return OBASectionTypeSubmit;

        case 3:
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

        case OBASectionTypeSubmit:
            return 2;

        case OBASectionTypeNotes:
            return 3;

        case OBASectionTypeNone:
        default:
            break;
    }
    return -1;
}

- (void)submit {
    OBAReportProblemWithStopV2 *problem = [[OBAReportProblemWithStopV2 alloc] init];

    problem.stopId = _stop.stopId;
    problem.code = _problemIds[_problemIndex];
    problem.userComment = _comment;
    problem.userLocation = [OBAApplication sharedApplication].locationManager.currentLocation;

    [_activityIndicatorView show:self.view];
    [[OBAApplication sharedApplication].modelService
     reportProblemWithStop:problem
           completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
               if (error || !responseData) {
               [self showErrorAlert];
               [self->_activityIndicatorView hide];
               }
               else {
               UIAlertView *view = [[UIAlertView alloc] init];
               view.title = NSLocalizedString(@"Submission Successful", @"view.title");
               [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategorySubmit
                                           action:@"report_problem"
                                            label:@"Reported Problem"
                                            value:nil];

               view.message = NSLocalizedString(@"The problem was sucessfully reported. Thank you!", @"view.message");
               [view addButtonWithTitle:NSLocalizedString(@"Dismiss", @"view addButtonWithTitle")];
               view.cancelButtonIndex = 0;
               [view show];
               [self->_activityIndicatorView hide];

               //go back to stop view
               NSArray *allViewControllers = self.navigationController.viewControllers;
               [self.navigationController
               popToViewController:[allViewControllers objectAtIndex:([allViewControllers count] - 3)]
                        animated:YES];
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
