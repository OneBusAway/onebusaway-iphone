#import "OBAApplicationDelegate.h"
#import "OBAArrivalEntryTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalEntryTableViewCellFactory : NSObject {
    OBAApplicationDelegate * _appDelegate;
    UITableView * _tableView;
    NSDateFormatter * _timeFormatter;
}

- (id) initWithappDelegate:(OBAApplicationDelegate*)appDelegate tableView:(UITableView*)tableView;

- (OBAArrivalEntryTableViewCell*) createCellForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrival;

@property (nonatomic) BOOL showServiceAlerts;

@end

NS_ASSUME_NONNULL_END