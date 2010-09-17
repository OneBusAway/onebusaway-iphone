#import "OBAApplicationContext.h"
#import "OBATripDetailsV2.h"


@interface OBATripScheduleListViewController : UITableViewController {
	OBAApplicationContext * _appContext;
	OBATripDetailsV2 * _tripDetails;	
	BOOL _showPreviousStops;
	NSInteger _currentStopIndex;
	
	NSDateFormatter * _timeFormatter;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)context tripDetails:(OBATripDetailsV2*)tripDetails;

@property (nonatomic,retain) NSString * currentStopId;

@end
