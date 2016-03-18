#import "OBAStopV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAReportProblemViewController : UITableViewController {
    OBAStopV2 * _stop;
}
- (id) initWithStop:(OBAStopV2*)stop;

@end

NS_ASSUME_NONNULL_END