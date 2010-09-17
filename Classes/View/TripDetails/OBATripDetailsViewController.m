#import "OBATripDetailsViewController.h"
#import "OBAUITableViewCell.h"
#import "OBATripScheduleListViewController.h"
#import "OBAReportAProblemViewController.h"
#import "OBALogger.h"


typedef enum {
	OBASectionTypeNone,
	OBASectionTypeTitle,
	OBASectionTypeSchedule,
	OBASectionTypeActions
} OBASectionType;


@interface OBATripDetailsViewController (Private)

- (void) clearPendingRequest;

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (UITableViewCell*) tableView:(UITableView*)tableView titleCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@implementation OBATripDetailsViewController

@synthesize tripDetails = _tripDetails;
@synthesize currentStopId;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext tripId:(NSString*)tripId {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_appContext = [appContext retain];
		_tripId = [tripId retain];
		
		_progressView = [[OBAProgressIndicatorView viewFromNib] retain];
		[self.navigationItem setTitleView:_progressView];
	}
	return self;
}

- (void)dealloc {
	[self clearPendingRequest];
	[_appContext release];
	[_tripId release];
	[_tripDetails release];
	[_progressView release];
    [super dealloc];
}

#pragma mark OBANavigationTargetAware

- (OBANavigationTarget*) navigationTarget {
	return nil;
}

#pragma mark UIViewController methods

- (void)viewWillAppear:(BOOL)animated {
    [self clearPendingRequest];
	[_progressView setMessage:@"Updating..." inProgress:TRUE progress:0];
	_request = [[_appContext.modelService requestTripDetailsForId:_tripId withDelegate:self withContext:nil] retain];
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
	OBAEntryWithReferencesV2 * entry = obj;
	self.tripDetails = entry.entry;
	[_progressView setMessage:@"Trip Details" inProgress:FALSE progress:0];
	[self.tableView reloadData];
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
	if( code == 404 )
		[_progressView setMessage:@"Stop not found" inProgress:FALSE progress:0];
	else
		[_progressView setMessage:@"Unknown error" inProgress:FALSE progress:0];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
	OBALogWarningWithError(error, @"Error");
	[_progressView setMessage:@"Error connecting" inProgress:FALSE progress:0];
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
	[_progressView setInProgress:TRUE progress:progress];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeSchedule:
			return @"Trip Schedule:";
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch( sectionType ) {
		case OBASectionTypeTitle:
			return 1;
		case OBASectionTypeSchedule:
			return 2;
		case OBASectionTypeActions:
			return 1;
		case OBASectionTypeNone:
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeTitle:
			return [self tableView:tableView titleCellForRowAtIndexPath:indexPath];
		case OBASectionTypeSchedule:
			return [self tableView:tableView scheduleCellForRowAtIndexPath:indexPath];
		case OBASectionTypeActions:
			return [self tableView:tableView actionCellForRowAtIndexPath:indexPath];
		default:
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
	
		case OBASectionTypeSchedule: {
			if( indexPath.row == 1 ) {
				if( _tripDetails ) {
					OBATripScheduleListViewController * vc = [[OBATripScheduleListViewController alloc] initWithApplicationContext:_appContext tripDetails:_tripDetails];
					[vc setCurrentStopId:self.currentStopId];
					[self.navigationController pushViewController:vc animated:TRUE];
					[vc release];
				}
			}
			break;			
		}
			
		case OBASectionTypeActions: {
			if( indexPath.row == 0 ) {
				if( _tripDetails ) {
					OBAReportAProblemViewController * vc = [[OBAReportAProblemViewController alloc] initWithApplicationContext:_appContext tripDetails:_tripDetails];
					[self.navigationController pushViewController:vc animated:TRUE];
					[vc release];
				}
			}
			break;
		}
		default:
			break;
	}
	
}

@end


@implementation OBATripDetailsViewController (Private)

- (void) clearPendingRequest {
	[_request cancel];
	[_request release];
	_request = nil;
}

- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	switch (section) {
		case 0:
			return OBASectionTypeTitle;
		case 1:
			return OBASectionTypeSchedule;
		case 2:
			return OBASectionTypeActions;
		default:
		return OBASectionTypeNone;
	}
}

- (UITableViewCell*) tableView:(UITableView*)tableView titleCellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
	cell.textLabel.textAlignment = UITextAlignmentCenter;	
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
	if( _tripDetails == nil ) {
		cell.textLabel.text = @"Updating...";
		cell.textLabel.textColor = [UIColor grayColor];
	}
	else {
		OBATripV2 * trip = _tripDetails.trip;
		cell.textLabel.text = trip.asLabel;
		cell.textLabel.textColor = [UIColor blackColor];
	}	
	
	return cell;
}


- (UITableViewCell*) tableView:(UITableView*)tableView scheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	
	switch (indexPath.row) {
		case 0:
			cell.textLabel.text = @"Show as map";
			break;
		case 1:
			cell.textLabel.text = @"Show as list";
			break;
	}
	
	return cell;
}


- (UITableViewCell*) tableView:(UITableView*)tableView actionCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
	
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	switch (indexPath.row) {
		case 0: {
			cell.textLabel.text = @"Report a problem for this trip";
			if( _tripDetails == nil ) {
				cell.textLabel.textColor = [UIColor grayColor];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
			}
			else {
				cell.textLabel.textColor = [UIColor blackColor];
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;	
			}
			break;
		}
	}
	
	return cell;
}

@end

