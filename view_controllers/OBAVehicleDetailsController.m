#import "OBAVehicleDetailsController.h"
#import "OBATripScheduleMapViewController.h"
#import "OBATripScheduleListViewController.h"
#import "OBAReportProblemWithTripViewController.h"
#import "OBASituationsViewController.h"
#import "OBALogger.h"
#import "OBAPresentation.h"


typedef enum {
    OBASectionTypeNone,
    OBASectionTypeVehicleDetails,
    OBASectionTypeTripDetails,
    OBASectionTypeTripSchedule
} OBASectionType;


@interface OBAVehicleDetailsController (Private)

- (OBASectionType) sectionTypeForSection:(NSUInteger)section;

- (UITableViewCell*) vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) tripDetailsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;
- (UITableViewCell*) tripScheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView;

- (void) didSelectTripScheduleRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;

@end


@implementation OBAVehicleDetailsController

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate vehicleId:(NSString*)vehicleId {
    if( self = [super initWithApplicationDelegate:appDelegate] ) {
        _vehicleId = vehicleId;
        self.refreshable = YES;
        self.refreshInterval = 30;
        self.showUpdateTime = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

- (BOOL) isLoading {
    return _vehicleStatus == nil;
}

- (id<OBAModelServiceRequest>) handleRefresh {
    return [_appDelegate.modelService requestVehicleForId:_vehicleId withDelegate:self withContext:nil];
}

-(void) handleData:(id)obj context:(id)context {
    OBAEntryWithReferencesV2 * entry = obj;
    _vehicleStatus = entry.entry;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if( [self isLoading] )
        return [super numberOfSectionsInTableView:tableView];
    
    int count = 1;
    if( _vehicleStatus.tripStatus )
        count += 2;
    return count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if( [self isLoading] )
        return [super tableView:tableView numberOfRowsInSection:section];
    
    OBASectionType sectionType = [self sectionTypeForSection:section];
    
    switch( sectionType ) {
        case OBASectionTypeVehicleDetails:
            return 1;
        case OBASectionTypeTripDetails:
            return 2;
        case OBASectionTypeTripSchedule:
            return 2;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if( [self isLoading] )
        return nil;
    
    OBASectionType sectionType = [self sectionTypeForSection:section];
    
    switch (sectionType) {
        case OBASectionTypeVehicleDetails:
            return NSLocalizedString(@"Vehicle Details:",@"OBASectionTypeVehicleDetails");
        case OBASectionTypeTripDetails:
            return NSLocalizedString(@"Active Trip Details:",@"OBASectionTypeTripDetails");
        case OBASectionTypeTripSchedule:
            return NSLocalizedString(@"Active Trip Schedule:",@"OBASectionTypeTripSchedule");
        default:
            return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( [self isLoading] )
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
    
    switch (sectionType) {
        case OBASectionTypeVehicleDetails:
            return [self vehicleCellForRowAtIndexPath:indexPath tableView:tableView];
        case OBASectionTypeTripDetails:
            return [self tripDetailsCellForRowAtIndexPath:indexPath tableView:tableView];
        case OBASectionTypeTripSchedule:
            return [self tripScheduleCellForRowAtIndexPath:indexPath tableView:tableView];
        default:
            break;
    }
    
    return [UITableViewCell getOrCreateCellForTableView:tableView];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if( [self isLoading] ) {
        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    
    OBASectionType sectionType = [self sectionTypeForSection:indexPath.section];
    
    switch (sectionType) {
        
        case OBASectionTypeTripSchedule:
            [self didSelectTripScheduleRowAtIndexPath:indexPath tableView:tableView];
            break;            

        default:
            break;
    }
    
}

@end


@implementation OBAVehicleDetailsController (Private)


- (OBASectionType) sectionTypeForSection:(NSUInteger)section {
    
    NSUInteger offset = 0;
    
    if( offset == section )
        return OBASectionTypeVehicleDetails;
    offset++;
    
    if( _vehicleStatus.tripStatus ) {
        if( offset == section )
            return OBASectionTypeTripDetails;
        offset++;
        
        if( offset == section )
            return OBASectionTypeTripSchedule;
        offset++;
    }
    
    return OBASectionTypeNone;
}

- (UITableViewCell*) vehicleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView style:UITableViewCellStyleSubtitle];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;

    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Vehicle",@"cell.textLabel.text"), _vehicleStatus.vehicleId];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];    
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:kCFDateFormatterNoStyle];    
    NSString * result = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_vehicleStatus.lastUpdateTime/1000.0]];

    cell.detailTextLabel.textColor = [UIColor blackColor];
    cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Last update",@"cell.detailTextLabel.text") , result];

    return cell;
}

- (UITableViewCell*) tripDetailsCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    
    OBATripStatusV2 * tripStatus = _vehicleStatus.tripStatus;
    OBATripV2 * trip = tripStatus.activeTrip;
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];    
    switch (indexPath.row) {
        case 0: {
            NSString * routeShortName = [OBAPresentation getRouteShortNameForRoute:trip.route];
            NSString * tripHeadsign = [OBAPresentation getTripHeadsignForTrip:trip];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", routeShortName, tripHeadsign];
            break;
        }
        case 1: {
            
            if( tripStatus.frequency ) { 
                cell.textLabel.text = [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Schedule deviation",@"cell.textLabel.text"),NSLocalizedString(@"N/A",@"cell.textLabel.text")];
            }
            else {
                NSInteger sd = tripStatus.scheduleDeviation;
                NSString * label = @" ";
                if( sd > 0 ) {
                    label = NSLocalizedString(@" late",@"sd > 0");
                }
                else if( sd < 0 ) {
                    label = NSLocalizedString(@" early",@"sd < 0");
                    sd = -sd;
                }
                
                NSInteger mins = sd / 60;
                NSInteger secs = sd % 60;
                
                cell.textLabel.text = [NSString stringWithFormat:@"%@: %dm %ds%@",NSLocalizedString(@"Schedule deviation",@"cell.textLabel.text"),mins, secs, label];
            }
            break;
        }
    }
    
    return cell;
}

- (UITableViewCell*) tripScheduleCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView*)tableView {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Show as map",@"VehicleDetailsController");
            
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"Show as list",@"VehicleDetailsController");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    
    OBASectionType sectionType = [self sectionTypeForSection:section];
    if (![self isLoading]) {
        switch (sectionType) {
            case OBASectionTypeVehicleDetails:
            case OBASectionTypeTripDetails:
            case OBASectionTypeTripSchedule:
                return 40;
            default:
                break;
        }
    }
    return 0;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    view.backgroundColor = OBAGREENBACKGROUND;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 30)];
    title.font = [UIFont systemFontOfSize:18];
    title.backgroundColor = [UIColor clearColor];;
    OBASectionType sectionType = [self sectionTypeForSection:section];
    if (![self isLoading]) {
        switch (sectionType) {
            case OBASectionTypeVehicleDetails:
                title.text = NSLocalizedString(@"Vehicle Details:",@"OBASectionTypeVehicleDetails");
                break;
            case OBASectionTypeTripDetails:
                title.text = NSLocalizedString(@"Active Trip Details:",@"OBASectionTypeTripDetails");
                break;
            case OBASectionTypeTripSchedule:
                title.text = NSLocalizedString(@"Active Trip Schedule:",@"OBASectionTypeTripSchedule");
                break;
            default:
                break;
        }
    }

    [view addSubview:title];
    return view;
}

- (void) didSelectTripScheduleRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    
    OBATripStatusV2 * tripStatus = _vehicleStatus.tripStatus;
    OBATripInstanceRef * tripInstance = tripStatus.tripInstance;
    
    switch (indexPath.row) {
        case 0: {
            OBATripScheduleMapViewController *vc = [[OBATripScheduleMapViewController alloc] initWithApplicationDelegate:_appDelegate];
            vc.tripInstance = tripInstance;
            [self.navigationController pushViewController:vc animated:YES];            
            break;
        }
        case 1: {
            OBATripScheduleListViewController * vc = [[OBATripScheduleListViewController alloc] initWithApplicationDelegate:_appDelegate tripInstance:tripInstance];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
    }
}

@end

