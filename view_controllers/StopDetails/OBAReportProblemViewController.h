#import "OBAApplicationDelegate.h"
#import "OBAStopV2.h"


@interface OBAReportProblemViewController : UITableViewController {
    OBAApplicationDelegate * _appContext;
    OBAStopV2 * _stop;
}

- (id) initWithApplicationContext:(OBAApplicationDelegate*)appContext stop:(OBAStopV2*)stop;

@end
