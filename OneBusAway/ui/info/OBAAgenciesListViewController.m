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
#import <SafariServices/SafariServices.h>
#import "OneBusAway-Swift.h"
@import SVProgressHUD;

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
        self.emptyDataSetTitle = NSLocalizedString(@"No Agencies", @"");
        self.emptyDataSetDescription = NSLocalizedString(@"We could not find any transit agencies near your current location.", @"");
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [SVProgressHUD show];
    [self.modelService requestAgenciesWithCoverage].then(^(NSArray<OBAAgencyWithCoverageV2*>* agencies) {
        self.agencies = [agencies sortedArrayUsingSelector:@selector(compareUsingAgencyName:)];
        [self loadData];
    }).always(^{
        [SVProgressHUD dismiss];
    }).catch(^(NSError *error) {
        [AlertPresenter showWarning:OBAStrings.error body:error.localizedDescription];
    });
}

- (void)loadData {
    OBATableSection *section = [[OBATableSection alloc] initWithTitle:nil];
    NSMutableArray * rows = [[NSMutableArray alloc] init];

    for (OBAAgencyWithCoverageV2 *awc in self.agencies) {
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:awc.agency.name action:^{
            SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:awc.agency.url]];
            safari.modalPresentationStyle = UIModalPresentationOverFullScreen;
            [self presentViewController:safari animated:YES completion:nil];
        }];
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        [rows addObject:row];
    }

    section.rows = rows;
    self.sections = @[section];
    [self.tableView reloadData];
}

#pragma mark - Lazy Loading

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

@end
