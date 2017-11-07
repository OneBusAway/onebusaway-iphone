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

#import "OBATripScheduleListViewController.h"
@import OBAKit;
#import "OBATripScheduleMapViewController.h"
#import "OBAStopViewController.h"
#import "OBAAnalytics.h"
#import "UITableViewCell+oba_Additions.h"
#import "UINavigationController+oba_Additions.h"
#import "OBATripScheduleSectionBuilder.h"

typedef NS_ENUM(NSUInteger, OBASectionType) {
    OBASectionTypeNone = 0,
    OBASectionTypeLoading,
    OBASectionTypeSchedule,
    OBASectionTypePreviousStops,
    OBASectionTypeConnections
};

@interface OBATripScheduleListViewController ()
@property(nonatomic,strong) OBATripInstanceRef *tripInstance;
@property(nonatomic,strong) OBAProgressIndicatorView *progressView;
@end

@implementation OBATripScheduleListViewController

- (instancetype)initWithTripInstance:(OBATripInstanceRef *)tripInstance {
    self = [super init];

    if (self) {
        _tripInstance = tripInstance;

        CGRect r = CGRectMake(0, 0, 160, 33);
        _progressView = [[OBAProgressIndicatorView alloc] initWithFrame:r];
        [self.navigationItem setTitleView:_progressView];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"msg_show_map", @"") style:UIBarButtonItemStylePlain target:self action:@selector(showMap:)];
        item.accessibilityLabel = NSLocalizedString(@"msg_map", @"initWithTitle");
        self.navigationItem.rightBarButtonItem = item;

        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"msg_schedule", @"initWithTitle") style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = backItem;
    }

    return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.tripDetails) {
        [self buildUI];
        return;
    }

    [self.modelService promiseTripDetailsFor:self.tripInstance].then(^(OBATripDetailsV2 *tripDetails) {
        self.tripDetails = tripDetails;
        [self buildUI];
    }).catch(^(NSError *error) {

        // TODO: replace this with an AlertPresenter.
        if (error.code == 404) {
            [self.progressView setMessage:NSLocalizedString(@"msg_trip_not_found", @"message") inProgress:NO progress:0];
        }
        else if (error.code >= 300) {
            [self.progressView setMessage:NSLocalizedString(@"msg_unknown_error", @"message") inProgress:NO progress:0];
        }
        else {
            DDLogError(@"Error: %@", error);
            [self.progressView setMessage:NSLocalizedString(@"msg_error_min_connecting", @"message") inProgress:NO progress:0];
        }
    });
}

#pragma mark - Lazily Loaded Properties

- (PromisedModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - Static tables

- (void)buildUI {
    NSMutableArray *sections = [[NSMutableArray alloc] init];

    OBATableSection *stopsSection = [OBATripScheduleSectionBuilder buildStopsSection:self.tripDetails tripInstance:self.tripInstance currentStopIndex:INT_MAX navigationController:self.navigationController];

    [sections addObject:stopsSection];

    self.sections = [NSArray arrayWithArray:sections];
    [self.tableView reloadData];

    NSUInteger stopIndex = [self currentStopIndex];
    if (stopIndex != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:stopIndex inSection:[self.sections indexOfObject:stopsSection]];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

#pragma mark - Actions

- (void)showMap:(id)sender {
    OBATripScheduleMapViewController *vc = [[OBATripScheduleMapViewController alloc] init];

    vc.tripDetails = _tripDetails;
    vc.currentStopId = self.currentStopId;
    [self.navigationController replaceViewController:vc animated:YES];
}

#pragma mark - Private

- (NSUInteger)currentStopIndex {
    return [OBATripScheduleSectionBuilder indexOfStopID:self.currentStopId inSchedule:self.tripDetails.schedule];
}

@end
