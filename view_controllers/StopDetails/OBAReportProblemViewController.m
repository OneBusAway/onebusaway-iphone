#import "OBAReportProblemViewController.h"
#import "OBAReportProblemWithStopViewController.h"
#import "OBAReportProblemWithRecentTripsViewController.h"


@implementation OBAReportProblemViewController


#pragma mark -
#pragma mark Initialization

- (id) initWithApplicationContext:(OBAApplicationDelegate*)context stop:(OBAStopV2*)stop {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _appContext = context;
        _stop = stop;
        
        self.navigationItem.title = NSLocalizedString(@"Report a Problem",@"self.navigationItem.title");
        
        UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Report",@"UIBarButtonItem initWithTitle") style:UIBarButtonItemStyleBordered target:nil action:nil];
        self.navigationItem.backBarButtonItem = item;
    }
    return self;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return NSLocalizedString(@"The problem is with:",@"tableView titleForHeaderInSection");
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
            OBAReportProblemWithStopViewController * vc = [[OBAReportProblemWithStopViewController alloc] initWithApplicationContext:_appContext stop:_stop];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 1: {
            OBAReportProblemWithRecentTripsViewController * vc = [[OBAReportProblemWithRecentTripsViewController alloc] initWithApplicationContext:_appContext stopId:_stop.stopId];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        default:
            break;
    }
}

@end

