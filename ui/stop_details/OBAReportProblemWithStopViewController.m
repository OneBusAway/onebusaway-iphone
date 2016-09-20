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

#import "OBAReportProblemWithStopViewController.h"
#import "UITableViewController+oba_Additions.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"
#import "OBAApplicationDelegate.h"
#import <OBAKit/OBAKit.h>

typedef NS_ENUM (NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeProblem,
    OBASectionTypeComment,
    OBASectionTypeSubmit,
    OBASectionTypeNotes
};

@interface OBAReportProblemWithStopViewController ()
@property(nonatomic,strong) OBAModalActivityIndicator * activityIndicatorView;
@end

@implementation OBAReportProblemWithStopViewController{
    OBAStopV2 * _stop;
    NSMutableArray * _problemIds;
    NSMutableArray * _problemNames;
    NSUInteger _problemIndex;
    NSString * _comment;
}

#pragma mark - Initialization

- (id)initWithStop:(OBAStopV2 *)stop {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
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

    view.backgroundColor = [OBATheme OBAGreenBackground];
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

#pragma mark - OBAListSelectionViewController

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
    problem.userLocation = self.locationManager.currentLocation;

    [self.activityIndicatorView show:self.view];
    [self.modelService reportProblemWithStop:problem completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {
        if (error || !responseData) {
            [self showErrorAlert];
            [self.activityIndicatorView hide];
            return;
        }

        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategorySubmit action:@"report_problem" label:@"Reported Problem" value:nil];

        [self.activityIndicatorView hide];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Submission Successful", @"view.title") message:NSLocalizedString(@"The problem was sucessfully reported. Thank you!", @"view.message") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:^{
            //go back to stop view
            NSArray *allViewControllers = self.navigationController.viewControllers;
            UIViewController *target = allViewControllers[allViewControllers.count - 3];
            [self.navigationController popToViewController:target animated:YES];
        }];
    }];
}

- (void)showErrorAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error Submitting", @"view.title")
                                                                   message:NSLocalizedString(@"An error occurred while reporting the problem. Please contact us directly.", @"view.message")
                                                            preferredStyle:UIAlertControllerStyleAlert];


    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Contact Us", @"view addButtonWithTitle") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [APP_DELEGATE navigateToTarget:[OBANavigationTarget target:OBANavigationTargetTypeContactUs]];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Lazy Loading

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

- (OBALocationManager*)locationManager {
    if (!_locationManager) {
        _locationManager = [OBAApplication sharedApplication].locationManager;
    }
    return _locationManager;
}

@end
