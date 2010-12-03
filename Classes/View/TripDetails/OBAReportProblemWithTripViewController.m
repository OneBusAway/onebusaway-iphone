#import "OBAReportProblemWithTripViewController.h"
#import "OBAUITableViewCell.h"
#import "OBAListSelectionViewController.h"
#import "OBATextEditViewController.h"
#import "OBALabelAndSwitchTableViewCell.h"
#import "OBALabelAndTextFieldTableViewCell.h"
#import "OBALogger.h"
#import "SBJSON.h"


typedef enum {
	OBASectionTypeNone,	
	OBASectionTypeProblem,
	OBASectionTypeComment,
	OBASectionTypeOnTheVehicle,
	OBASectionTypeSubmit,
	OBASectionTypeNotes
} OBASectionType;


@interface OBAReportProblemWithTripViewController (Private)

- (void) addProblemWithId:(NSString*)problemId name:(NSString*)problemName;

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;
- (NSUInteger) sectionIndexForType:(OBASectionType)type;

- (UITableViewCell*) tableView:(UITableView*)tableView vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSString*) getVehicleTypeLabeForTrip:(OBATripV2*)trip;

- (void) submit;
- (NSString*) getProblemAsData;

@end


@implementation OBAReportProblemWithTripViewController

@synthesize currentStopId;

#pragma mark -
#pragma mark Initialization

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext tripInstance:(OBATripInstanceRef*)tripInstance trip:(OBATripV2*)trip {
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_appContext = [appContext retain];
		_tripInstance = [tripInstance retain];
		_trip = [trip retain];

		self.navigationItem.title = @"Report a Problem";

		UIBarButtonItem * item = [[UIBarButtonItem alloc] initWithTitle:@"Custom Title"
										 style:UIBarButtonItemStyleBordered
										target:nil
										action:nil];
		self.navigationItem.backBarButtonItem = item;
		[item release];
		
		_vehicleNumber = @"0000";
		_vehicleType = [self getVehicleTypeLabeForTrip:trip];
		
		_problemIds = [[NSMutableArray alloc] init];
		_problemNames = [[NSMutableArray alloc] init];

		[self addProblemWithId:@"vehicle_never_came" name:[NSString stringWithFormat:@"The %@ never came",_vehicleType]];
		[self addProblemWithId:@"vehicle_came_early" name:@"It came earlier than predicted"];
		[self addProblemWithId:@"vehicle_came_late" name:@"It came later than predicted"];
		[self addProblemWithId:@"wrong_headsign" name:@"Wrong destination shown"];
		[self addProblemWithId:@"vehicle_does_not_stop_here" name:[NSString stringWithFormat:@"The %@ doesn't stop here",_vehicleType]];
		[self addProblemWithId:@"other" name:@"Other"];
		
		_activityIndicatorView = [[OBAModalActivityIndicator alloc] init];		
    }
    return self;
}

- (void)dealloc {
	[_appContext release];
	[_problemNames release];
	[_tripInstance release];
	[_comment release];
	[_activityIndicatorView release];
    [super dealloc];
}


#pragma mark UIViewController

-(void)viewDidLoad {
	self.navigationItem.backBarButtonItem.title = @"Problem";
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch (sectionType) {
		case OBASectionTypeProblem:
			return @"What's the problem?";
		case OBASectionTypeComment:
			return @"Optional - Comment:";
		case OBASectionTypeOnTheVehicle:
			return [NSString stringWithFormat:@"Optional - Are you on this %@?",_vehicleType];
		case OBASectionTypeNotes:
			return @"Your reports help OneBusAway find and fix problems with the system.";
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	OBASectionType sectionType = [self sectionTypeForSection:section];
	
	switch( sectionType ) {
		case OBASectionTypeProblem:
			return 1;
		case OBASectionTypeComment:
			return 1;
		case OBASectionTypeOnTheVehicle:
			return 2;
		case OBASectionTypeSubmit:
			return 1;
		case OBASectionTypeNotes:
			return 0;
		case OBASectionTypeNone:
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	
	switch (sectionType) {
		case OBASectionTypeProblem: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];			
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = [_problemNames objectAtIndex:_problemIndex];
			return cell;			
		}
		case OBASectionTypeComment: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];			
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			if (_comment && [_comment length] > 0) {
				cell.textLabel.textColor = [UIColor blackColor];
				cell.textLabel.text = _comment;
			}
			else {
				cell.textLabel.textColor = [UIColor grayColor];
				cell.textLabel.text = @"Touch to edit";
			}
			
			return cell;
		}
		
		case OBASectionTypeOnTheVehicle:
			return [self tableView:tableView vehicleCellForRowAtIndexPath:indexPath];

		case OBASectionTypeSubmit: {
			UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];			
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.text = @"Submit";
			return cell;
		}
		default:	
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
	switch (sectionType) {
		case OBASectionTypeProblem: {
			NSIndexPath * selectedIndex = [NSIndexPath indexPathForRow:_problemIndex inSection:0];			
			OBAListSelectionViewController * vc = [[OBAListSelectionViewController alloc] initWithValues:_problemNames selectedIndex:selectedIndex];
			vc.target = self;
			vc.action = @selector(setProblem:);
			[self.navigationController pushViewController:vc animated:TRUE];
			[vc release];
			break;
		}
			
		case OBASectionTypeComment: {
			OBATextEditViewController * vc = [OBATextEditViewController pushOntoViewController:self withText:_comment withTitle:@"Comment"];
			vc.target = self;
			vc.action = @selector(setComment:);
			break;
		}
			
		case OBASectionTypeSubmit: {
			[self submit];
		}
			
		default:
			break;
	}
}


#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
	return YES;
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
	[_activityIndicatorView hide];
	[self.navigationController popViewControllerAnimated:TRUE];
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
	[_activityIndicatorView hide];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
	[_activityIndicatorView hide];
	OBALogSevereWithError(error,@"problem posting problem");
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {

}


#pragma mark Other methods

- (void) setProblem:(NSIndexPath*)indexPath {
	_problemIndex = indexPath.row;
	NSUInteger section = [self sectionIndexForType:OBASectionTypeProblem];
	NSIndexPath * p = [NSIndexPath indexPathForRow:0 inSection:section];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:p] withRowAnimation:UITableViewRowAnimationFade];
}

- (void) setComment:(NSString*)comment {
	_comment = [NSObject releaseOld:_comment retainNew:comment];
	NSUInteger section = [self sectionIndexForType:OBASectionTypeComment];
	NSIndexPath * p = [NSIndexPath indexPathForRow:0 inSection:section];
	[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:p] withRowAnimation:UITableViewRowAnimationFade];
}

- (void) setOnVehicle:(id) obj {
	UISwitch * toggleSwitch = obj;
	_onVehicle = toggleSwitch.on;
}

- (void) setVehicleNumber:(id) obj {
	UITextField * textField = obj;	
	_vehicleNumber = [NSObject releaseOld:_vehicleNumber retainNew:[textField text]];
}

@end


@implementation OBAReportProblemWithTripViewController (Private)

- (void) addProblemWithId:(NSString*)problemId name:(NSString*)problemName {
	[_problemIds addObject:problemId];
	[_problemNames addObject:problemName];
}

- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
	switch (section) {
		case 0:
			return OBASectionTypeProblem;
		case 1:
			return OBASectionTypeComment;
		case 2:
			return OBASectionTypeOnTheVehicle;
		case 3:
			return OBASectionTypeSubmit;
		case 4:
			return OBASectionTypeNotes;
		default:
			return OBASectionTypeNone;
	}
}

- (NSUInteger) sectionIndexForType:(OBASectionType)type {
	switch (type) {
		case OBASectionTypeProblem:
			return 0;
		case OBASectionTypeComment:
			return 1;
		case OBASectionTypeOnTheVehicle:
			return 2;
		case OBASectionTypeSubmit:
			return 3;
		case OBASectionTypeNotes:
			return 4;
		case OBASectionTypeNone:
		default:
			break;
	}
	return -1;
}

- (UITableViewCell*) tableView:(UITableView*)tableView vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath {

	switch (indexPath.row) {
		case 0: {
			OBALabelAndSwitchTableViewCell * cell = [OBALabelAndSwitchTableViewCell getOrCreateCellForTableView:tableView];
			cell.label.text = [NSString stringWithFormat:@"On this %@?",[_vehicleType capitalizedString]];
			[cell.toggleSwitch setOn:_onVehicle];
			[cell.toggleSwitch addTarget:self action:@selector(setOnVehicle:) forControlEvents:UIControlEventValueChanged];
			return cell;
		}
		case 1: {
			OBALabelAndTextFieldTableViewCell * cell = [OBALabelAndTextFieldTableViewCell getOrCreateCellForTableView:tableView];
			cell.label.text = [NSString stringWithFormat:@"%@ Number",[_vehicleType capitalizedString]];
			
			cell.textField.text = _vehicleNumber;
			cell.textField.delegate = self;
			[cell.textField addTarget:self action:@selector(setVehicleNumber:) forControlEvents:UIControlEventEditingChanged];
			[cell setNeedsLayout];
			return cell;
		}
		default:
			break;
	}
	
	return [UITableViewCell getOrCreateCellForTableView:tableView];
}

- (NSString*) getVehicleTypeLabeForTrip:(OBATripV2*)trip {
	
	OBARouteV2 * route = trip.route;

	switch ([route.routeType intValue]) {
		case 0:
		case 1:
		case 2:
			return @"train";
		case 3:
			return @"bus";
		case 4:
			return @"ferry";
		default:
			return @"vehicle";
	}
}

- (void) submit {

	OBAReportProblemWithTripV2 * problem = [[OBAReportProblemWithTripV2 alloc] init];
	problem.tripInstance = _tripInstance;
	problem.stopId = self.currentStopId;
	problem.data = [self getProblemAsData];
	problem.userComment = _comment;
	problem.userOnVehicle = _onVehicle;
	problem.userVehicleNumber = _vehicleNumber;
	problem.userLocation = _appContext.locationManager.currentLocation;
	
	
	[_activityIndicatorView show:self.view];
	[_appContext.modelService reportProblemWithTrip:problem withDelegate:self withContext:nil];
	
	[problem release];
}

- (NSString*) getProblemAsData {

	NSMutableDictionary * p = [[NSMutableDictionary alloc] init];
	[p setObject:[_problemIds objectAtIndex:_problemIndex] forKey:@"code"];
	[p setObject:[_problemNames objectAtIndex:_problemIndex] forKey:@"text"];
	
	SBJSON * json = [[SBJSON alloc] init];
	NSString * v = [json stringWithObject:p];
	[json release];
	[p release];
	return v;	
}

@end