#import "OBAApplicationDelegate.h"
#import "OBAStopV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAReportProblemViewController : UITableViewController {
    OBAApplicationDelegate * _appDelegate;
    OBAStopV2 * _stop;
}
- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate stop:(OBAStopV2*)stop;

@end

NS_ASSUME_NONNULL_END