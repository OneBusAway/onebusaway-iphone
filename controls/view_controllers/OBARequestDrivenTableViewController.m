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

#import "OBARequestDrivenTableViewController.h"
#import "OBAAnalytics.h"
#import "UITableViewCell+oba_Additions.h"
#import <OBAKit/OBAKit.h>
#import "EXTScope.h"

@interface OBARequestDrivenTableViewController ()

@property (nonatomic, copy, readwrite) OBADataSourceProgress progressCallback;

@property (nonatomic, strong)  OBAProgressIndicatorView *progressView;
@end


@implementation OBARequestDrivenTableViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];

    if (self) {
        CGRect r = CGRectMake(0, 0, 160, 33);
        _progressView = [[OBAProgressIndicatorView alloc] initWithFrame:r];
        [self.navigationItem setTitleView:_progressView];
        _progressLabel = @"";
        _showUpdateTime = NO;

        @weakify(self);
        self.progressCallback = ^(CGFloat progress) {
            @strongify(self);
            [self.progressView setInProgress:YES progress:progress];
            [self didRefreshEnd];
        };
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self hideEmptySeparators];
}

- (void)dealloc {
    [self clearPendingRequest];
}

- (void)setRefreshable:(BOOL)refreshable {
    _refreshable = refreshable;

    if (_refreshable) {
        UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshButton:)];
        [self.navigationItem setRightBarButtonItem:refreshItem];
    }
    else {
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (void)setRefreshInterval:(NSInteger)refreshInterval {
    _refreshInterval = refreshInterval;
    [self checkTimer];
}

- (BOOL)isLoading {
    return YES;
}

- (void)refresh {
    [_progressView setMessage:@"Updating..." inProgress:YES progress:0];
    [self didRefreshBegin];
    [self clearPendingRequest];
    _request = [self handleRefresh];
    [self checkTimer];
}

- (id<OBAModelServiceRequest>)handleRefresh {
    return nil;
}

#pragma mark UIViewController methods

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self clearPendingRequest];

    if ([self isLoading]) {
        [self refresh];
    }
    else {
        [self checkTimer];
        [self refreshProgressLabel];
        [self didRefreshEnd];
        [self.tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self clearPendingRequest];
}

#pragma mark OBAModelServiceDelegate

- (void)updateProgress:(CGFloat)progress {
}

- (void)refreshCompleteWithCode:(NSUInteger)statusCode {
    if (200 <= statusCode && statusCode < 300) {
        [self refreshProgressLabel];
        [self.tableView reloadData];
    }
    else if (statusCode == 404) {
        [_progressView setMessage:@"Not found" inProgress:NO progress:0];
    }
    else {
        [_progressView setMessage:@"Unknown error" inProgress:NO progress:0];
    }

    [self didRefreshEnd];
}

- (void)refreshFailedWithError:(NSError *)error {
    NSLog(@"Error: %@", error);
    [_progressView setMessage:@"Error connecting" inProgress:NO progress:0];
    [self didRefreshEnd];
}

#pragma mark - Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    cell.textLabel.text = NSLocalizedString(@"Updating...",@"");
    cell.textLabel.font = [OBATheme bodyFont];
    cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)clearPendingRequest {
    [_timer invalidate];
    _timer = nil;

    [_request cancel];
    _request = nil;
}

- (IBAction)onRefreshButton:(id)sender {
    [self refresh];
}

- (void)checkTimer {
    if (_refreshInterval > 0) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:_refreshInterval target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    }
    else {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)refreshProgressLabel {
    NSString *label = _progressLabel;

    if (_showUpdateTime) label = [NSString stringWithFormat:@"Updated: %@", [OBACommon getTimeAsString]];

    [_progressView setMessage:label inProgress:NO progress:0];
}

- (void)didRefreshBegin {
    UIBarButtonItem *refreshItem = [self.navigationItem rightBarButtonItem];

    if (refreshItem) [refreshItem setEnabled:NO];
}

- (void)didRefreshEnd {
    UIBarButtonItem *refreshItem = [self.navigationItem rightBarButtonItem];

    if (refreshItem) [refreshItem setEnabled:YES];
}

@end
