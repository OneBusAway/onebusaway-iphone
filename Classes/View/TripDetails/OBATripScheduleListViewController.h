#import "OBAApplicationContext.h"
#import "OBATripDetailsV2.h"


@interface OBATripScheduleListViewController : UITableViewController {
	OBAApplicationContext * _appContext;
	OBATripDetailsV2 * _tripDetails;	
	BOOL _showPreviousStops;
	NSInteger _currentStopIndex;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)context tripDetails:(OBATripDetailsV2*)tripDetails;

- (void) setCurrentStopId:(NSString*)stopId;

@end
