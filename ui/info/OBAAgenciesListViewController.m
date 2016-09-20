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

#import "OBAAgenciesListViewController.h"
#import "OBAAnalytics.h"
#import "UITableViewCell+oba_Additions.h"
#import <SafariServices/SafariServices.h>
#import "EXTScope.h"
#import "OBAApplicationDelegate.h"

typedef NS_ENUM (NSInteger, OBASectionType) {
    OBASectionTypeNone,
    OBASectionTypeActions,
    OBASectionTypeAgencies,
    OBASectionTypeNoAgencies,
};

@interface OBAAgenciesListViewController ()
@property(nonatomic,copy) NSArray<OBAAgencyWithCoverageV2 *> *agencies;
@end

@implementation OBAAgenciesListViewController

- (id)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Agencies", @"Agencies tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"Agencies"];
        self.refreshable = NO;
        self.showUpdateTime = NO;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.refreshable = NO;
    self.showUpdateTime = NO;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

- (BOOL)isLoading {
    return self.agencies == nil;
}

- (id<OBAModelServiceRequest>)handleRefresh {
    @weakify(self);
    return [self.modelService requestAgenciesWithCoverage:^(id jsonData, NSUInteger responseCode, NSError *error) {
        @strongify(self);
        
        if (error) {
            [self refreshFailedWithError:error];
        }
        else {
            OBAListWithRangeAndReferencesV2 *list = jsonData;
            self.agencies = [NSArray arrayWithArray:list.values];
            self.agencies = [self.agencies sortedArrayUsingSelector:@selector(compareUsingAgencyName:)];
            self.progressLabel = NSLocalizedString(@"Agencies", @"");
            [self refreshCompleteWithCode:responseCode];
        }
    }];
}

#pragma mark - Lazy Loading

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self isLoading]) {
        return [super numberOfSectionsInTableView:tableView];
    }

    if (self.agencies.count == 0) {
        return 1;
    }
    else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isLoading]) {
        return [super tableView:tableView numberOfRowsInSection:section];
    }

    OBASectionType sectionType = [self sectionTypeForSection:section];

    switch (sectionType) {
        case OBASectionTypeActions:
            return 1;

        case OBASectionTypeAgencies:
            return self.agencies.count;

        case OBASectionTypeNoAgencies:
            return 1;

        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLoading]) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }

    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeActions:
            return [self actionsCellForRowAtIndexPath:indexPath tableView:tableView];

        case OBASectionTypeAgencies:
            return [self agenciesCellForRowAtIndexPath:indexPath tableView:tableView];

        case OBASectionTypeNoAgencies:
            return [self noAgenciesCellForRowAtIndexPath:indexPath tableView:tableView];

        default:
            break;
    }

    return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLoading]) {
        return;
    }

    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];

    switch (sectionType) {
        case OBASectionTypeActions:
            [self didSelectActionsRowAtIndexPath:indexPath tableView:tableView];
            break;

        case OBASectionTypeAgencies:
            [self didSelectAgencyRowAtIndexPath:indexPath tableView:tableView];
            break;

        default:
            break;
    }
}

- (OBASectionType)sectionTypeForSection:(NSUInteger)section {
    if (self.agencies.count == 0) {
        if (section == 0) {
            return OBASectionTypeNoAgencies;
        }
    }
    else {
        if (section == 0) {
            return OBASectionTypeActions;
        }
        else if (section == 1) {
            return OBASectionTypeAgencies;
        }
    }

    return OBASectionTypeNone;
}

- (UITableViewCell *)actionsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = NSLocalizedString(@"Show on Map", @"AgenciesListViewController");
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
     if (section == 0) {
        UIView *footer = [[UIView alloc] init];
        footer.backgroundColor = [OBATheme OBAGreenBackground];
        return footer;
    }
    else {
        return nil;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return 33;
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)agenciesCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {

    OBAAgencyWithCoverageV2 *awc = self.agencies[indexPath.row];
    OBAAgencyV2 *agency = awc.agency;

    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.text = agency.name;
    return cell;
}

- (UITableViewCell *)noAgenciesCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = NSLocalizedString(@"No agencies found", @"cell.textLabel.text");
    return cell;
}

- (void)didSelectActionsRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    OBANavigationTarget *target = [OBASearch getNavigationTargetForSearchAgenciesWithCoverage];
    [APP_DELEGATE navigateToTarget:target];
}

- (void)didSelectAgencyRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    OBAAgencyWithCoverageV2 *awc = self.agencies[indexPath.row];
    OBAAgencyV2 *agency = awc.agency;

    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:agency.url]];
    safari.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:safari animated:YES completion:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
