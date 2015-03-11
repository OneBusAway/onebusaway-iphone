#import "OBARequestDrivenTableViewController.h"
#import "OBALogger.h"
#import "OBAAnalytics.h"


@interface OBARequestDrivenTableViewController ()

@property (nonatomic, copy, readwrite) OBADataSourceProgress progressCallback;

@property (nonatomic, strong)  OBAProgressIndicatorView *progressView;
@end


@implementation OBARequestDrivenTableViewController

- (id)initWithApplicationDelegate:(OBAApplicationDelegate *)appDelegate {
    self = [super initWithStyle:UITableViewStylePlain];

    if (self) {
        _appDelegate = appDelegate;
        CGRect r = CGRectMake(0, 0, 160, 33);
        _progressView = [[OBAProgressIndicatorView alloc] initWithFrame:r];
        [self.navigationItem setTitleView:_progressView];
        _progressLabel = @"";
        _showUpdateTime = NO;


        __weak OBARequestDrivenTableViewController *weakSelf = self;
        self.progressCallback =  ^(CGFloat progress) {
            [weakSelf.progressView setInProgress:YES progress:progress];
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
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(onRefreshButton:) forControlEvents:UIControlEventValueChanged];
        [self setRefreshControl:refreshControl];
    }
    else {
        [self setRefreshControl:NULL];
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
        [self.tableView reloadData];
    }

    [OBAAnalytics reportScreenView:[NSString stringWithFormat:@"View: %@", [self class]]];
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

    
    [self.refreshControl endRefreshing];
}

- (void)refreshFailedWithError:(NSError *)error {
    OBALogWarningWithError(error, @"Error");
    [_progressView setMessage:@"Error connecting" inProgress:NO progress:0];
    
    [self.refreshControl endRefreshing];
}

#pragma mark - Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView];

    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    cell.textLabel.text = @"Updating...";
    cell.textLabel.font = [UIFont systemFontOfSize:18];
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

@end
