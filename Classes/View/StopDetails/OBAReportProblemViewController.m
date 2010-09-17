#import "OBAReportProblemViewController.h"
#import "OBAReportProblemWithStopViewController.h"
#import "OBAReportProblemWithRecentTripsViewController.h"
#import "OBAUITableViewCell.h"


@implementation OBAReportProblemViewController


#pragma mark -
#pragma mark Initialization

- (id) initWithApplicationContext:(OBAApplicationContext*)context stop:(OBAStopV2*)stop {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_appContext = [context retain];
		_stop = [stop retain];
		
		self.navigationItem.title = @"Report a Problem";
		
		UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:@"Report" style:UIBarButtonItemStyleBordered target:nil action:nil];
		self.navigationItem.backBarButtonItem = item;
		[item release];
    }
    return self;
}

- (void) dealloc {
	[_appContext release];
	[_stop release];
	[super dealloc];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	return @"The problem is with:";
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
			cell.textLabel.text = @"The stop itself";
			break;
		case 1:
			cell.textLabel.text = @"A bus/train/etc at this stop";
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
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			break;
		}
		case 1: {
			OBAReportProblemWithRecentTripsViewController * vc = [[OBAReportProblemWithRecentTripsViewController alloc] initWithApplicationContext:_appContext stopId:_stop.stopId];
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			break;
		}
		default:
			break;
	}
}

@end

