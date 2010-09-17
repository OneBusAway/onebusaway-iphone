#import "OBAApplicationContext.h"
#import "OBAStopV2.h"


@interface OBAReportProblemViewController : UITableViewController {
	OBAApplicationContext * _appContext;
	OBAStopV2 * _stop;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext stop:(OBAStopV2*)stop;

@end
