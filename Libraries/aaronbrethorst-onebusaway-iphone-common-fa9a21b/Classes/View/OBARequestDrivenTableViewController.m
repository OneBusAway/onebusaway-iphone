#import "OBARequestDrivenTableViewController.h"
#import "OBALogger.h"


@interface OBARequestDrivenTableViewController (Private)

- (void) clearPendingRequest;

- (void) checkTimer;
- (void) refreshProgressLabel;
- (void) didRefreshBegin;
- (void) didRefreshEnd;

@end


@implementation OBARequestDrivenTableViewController

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate { 
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _appDelegate = appDelegate;
        CGRect r = CGRectMake(0, 0, 160, 33);
        _progressView = [[OBAProgressIndicatorView alloc] initWithFrame:r];
        [self.navigationItem setTitleView:_progressView];
        _progressLabel = @"";
        _showUpdateTime = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self hideEmptySeparators];
}

- (void)dealloc {
    [self clearPendingRequest];
}

- (BOOL) refreshable {
    return _refreshable;
}

- (void) setRefreshable:(BOOL)refreshable {
    _refreshable = refreshable;

    if( _refreshable ) {
        UIBarButtonItem * refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(onRefreshButton:)];
        [self.navigationItem setRightBarButtonItem:refreshItem];
    }
    else {
        [self.navigationItem setRightBarButtonItem:nil];
    }
}

- (NSInteger) refreshInterval {
    return _refreshInterval;
}

- (void) setRefreshInterval:(NSInteger)refreshInterval {
    _refreshInterval = refreshInterval;
    [self checkTimer];
}

- (BOOL) isLoading {
    return YES;
}

- (void) refresh {
    [_progressView setMessage:@"Updating..." inProgress:YES progress:0];
    [self didRefreshBegin];
    [self clearPendingRequest];
    _request = [self handleRefresh];
    [self checkTimer];
}

- (id<OBAModelServiceRequest>) handleRefresh {
    return nil;
}

- (void) handleData:(id)obj context:(id)context {
    
}

- (void) handleDataChanged {
    
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
        [self handleDataChanged];
        [self.tableView reloadData];
    }

    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)viewWillDisappear:(BOOL)animated {    
    [self clearPendingRequest];
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    [self handleData:obj context:context];
    [self refreshProgressLabel];
    [self didRefreshEnd];
    [self handleDataChanged];
    [self.tableView reloadData];
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
    if( code == 404 )
        [_progressView setMessage:@"Not found" inProgress:NO progress:0];
    else
        [_progressView setMessage:@"Unknown error" inProgress:NO progress:0];
    [self didRefreshEnd];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
    OBALogWarningWithError(error, @"Error");
    [_progressView setMessage:@"Error connecting" inProgress:NO progress:0];
    [self didRefreshEnd];
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    [_progressView setInProgress:YES progress:progress];
    [self didRefreshEnd];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.text = @"Updating...";
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.textAlignment = UITextAlignmentCenter;    
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

@end


@implementation OBARequestDrivenTableViewController (Private)

- (void) clearPendingRequest {
    [_timer invalidate];
    _timer = nil;
    
    [_request cancel];
    _request = nil;
}

- (IBAction)onRefreshButton:(id)sender {
    [self refresh];
}

- (void) checkTimer {
    if( _refreshInterval > 0 ) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:_refreshInterval target:self selector:@selector(refresh) userInfo:nil repeats:YES];
    }
    else {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void) refreshProgressLabel {
    NSString * label = _progressLabel;
    if( _showUpdateTime )
        label = [NSString stringWithFormat:@"Updated: %@", [OBACommon getTimeAsString]];
    [_progressView setMessage:label inProgress:NO progress:0];
}

- (void) didRefreshBegin {    
    UIBarButtonItem * refreshItem = [self.navigationItem rightBarButtonItem];
    if( refreshItem )
        [refreshItem setEnabled:NO];
    
}

- (void) didRefreshEnd {
    UIBarButtonItem * refreshItem = [self.navigationItem rightBarButtonItem];
    if( refreshItem )
        [refreshItem setEnabled:YES];
}

@end

