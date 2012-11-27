#import "OBAApplicationDelegate.h"
#import "OBAArrivalEntryTableViewCell.h"


@interface OBAArrivalEntryTableViewCellFactory : NSObject {
    OBAApplicationDelegate * _appContext;
    UITableView * _tableView;
    NSDateFormatter * _timeFormatter;
    BOOL _showServiceAlerts;
}

- (id) initWithAppContext:(OBAApplicationDelegate*)appContext tableView:(UITableView*)tableView;

- (OBAArrivalEntryTableViewCell*) createCellForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrival;

@property (nonatomic) BOOL showServiceAlerts;

@end
