#import "OBAArrivalEntryTableViewCell.h"
#import "OBAArrivalAndDepartureV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalEntryTableViewCellFactory : NSObject {
    UITableView * _tableView;
    NSDateFormatter * _timeFormatter;
}

- (id) initWithTableView:(UITableView*)tableView;

- (OBAArrivalEntryTableViewCell*) createCellForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrival;

@property (nonatomic) BOOL showServiceAlerts;

@end

NS_ASSUME_NONNULL_END