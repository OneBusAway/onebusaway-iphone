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
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"
#import "OBAApplicationDelegate.h"
#import "OneBusAway-Swift.h"
@import SVProgressHUD;

typedef NS_ENUM (NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeProblem,
    OBASectionTypeComment,
    OBASectionTypeSubmit,
    OBASectionTypeNotes
};

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

        self.navigationItem.title = NSLocalizedString(@"msg_report_a_problem", @"self.navigationItem.title");

        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"msg_custom_title", @"UIBarButtonItem * item")
                                                                 style:UIBarButtonItemStylePlain
                                                                target:nil
                                                                action:nil];
        self.navigationItem.backBarButtonItem = item;

        _problemIds = [[NSMutableArray alloc] init];
        _problemNames = [[NSMutableArray alloc] init];

        [self addProblemWithId:@"stop_name_wrong" name:NSLocalizedString(@"msg_stop_name_wrong", @"name")];
        [self addProblemWithId:@"stop_number_wrong" name:NSLocalizedString(@"msg_stop_number_wrong", @"name")];
        [self addProblemWithId:@"stop_location_wrong" name:NSLocalizedString(@"msg_stop_location_wrong", @"name")];
        [self addProblemWithId:@"route_or_trip_missing" name:NSLocalizedString(@"msg_route_or_trip_missing", @"name")];
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
            title.text = NSLocalizedString(@"msg_ask_whats_the_problem", @"OBASectionTypeProblem");
            break;

        case OBASectionTypeComment:
            title.text = NSLocalizedString(@"msg_optional_comment", @"OBASectionTypeComment");
            break;

        case OBASectionTypeSubmit:
            view.frame = CGRectMake(0, 0, 320, 70);
            title.numberOfLines = 2;
            title.frame = CGRectMake(15, 5, 290, 60);
            title.text = NSLocalizedString(@"msg_explanatory_send_reports", @"OBASectionTypeSubmit");
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

    [SVProgressHUD show];
    [self.modelService reportProblemWithStop:problem completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
        [SVProgressHUD dismiss];

        if (error || !responseData) {
            [AlertPresenter showError:error];
            return;
        }

        [OBAAnalytics reportEventWithCategory:OBAAnalyticsCategorySubmit action:@"report_problem" label:@"Reported Problem" value:nil];

        [self dismissViewControllerAnimated:YES completion:^{
            [AlertPresenter showSuccess:NSLocalizedString(@"msg_submission_successful",) body:NSLocalizedString(@"msg_sucessfull_report_send",)];
        }];
    }];
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
