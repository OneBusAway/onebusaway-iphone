#import "OBAReportProblemViewController.h"
#import "OBAReportProblemWithStopViewController.h"
#import "OBAReportProblemWithRecentTripsViewController.h"
#import "UITableViewController+oba_Additions.h"

@implementation OBAReportProblemViewController


#pragma mark -
#pragma mark Initialization

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)context stop:(OBAStopV2*)stop {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _appDelegate = context;
        _stop = stop;
        
        self.navigationItem.title = NSLocalizedString(@"Report a Problem",@"self.navigationItem.title");
        
        UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Report",@"UIBarButtonItem initWithTitle") style:UIBarButtonItemStyleBordered target:nil action:nil];
        self.navigationItem.backBarButtonItem = item;
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self hideEmptySeparators];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    view.backgroundColor = OBAGREENBACKGROUND;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 30)];
    title.font = [UIFont systemFontOfSize:18];
    title.backgroundColor = [UIColor clearColor];;
    title.text = NSLocalizedString(@"The problem is with:",@"tableView titleForHeaderInSection");
    [view addSubview:title];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];            
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"The stop itself",@"case 0 cell.textLabel.text");
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"A bus/train/etc at this stop",@"case 1 cell.textLabel.text");
            break;
        default:
            break;
    }
    return cell;            
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            OBAReportProblemWithStopViewController * vc = [[OBAReportProblemWithStopViewController alloc] initWithApplicationDelegate:_appDelegate stop:_stop];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 1: {
            OBAReportProblemWithRecentTripsViewController * vc = [[OBAReportProblemWithRecentTripsViewController alloc] initWithApplicationDelegate:_appDelegate stopId:_stop.stopId];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default:
            break;
    }
}

@end

