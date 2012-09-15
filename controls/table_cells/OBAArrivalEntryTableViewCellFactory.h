#import "OBAApplicationContext.h"
#import "OBAArrivalEntryTableViewCell.h"


@interface OBAArrivalEntryTableViewCellFactory : NSObject {
	OBAApplicationContext * _appContext;
	UITableView * _tableView;
	NSDateFormatter * _timeFormatter;
	BOOL _showServiceAlerts;
}

- (id) initWithAppContext:(OBAApplicationContext*)appContext tableView:(UITableView*)tableView;

- (OBAArrivalEntryTableViewCell*) createCellForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrival;

@property (nonatomic) BOOL showServiceAlerts;

@end
