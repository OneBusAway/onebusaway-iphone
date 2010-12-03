#import "OBAApplicationContext.h"
#import "OBATripDetailsV2.h"
#import "OBATripInstanceRef.h"
#import "OBAProgressIndicatorView.h"


@interface OBATripScheduleListViewController : UITableViewController <OBAModelServiceDelegate> {
	OBAApplicationContext * _appContext;
	OBATripInstanceRef * _tripInstance;
	OBATripDetailsV2 * _tripDetails;	
	id<OBAModelServiceRequest> _request;
	BOOL _showPreviousStops;
	NSInteger _currentStopIndex;
	
	NSDateFormatter * _timeFormatter;
	OBAProgressIndicatorView * _progressView;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)context tripInstance:(OBATripInstanceRef*)tripInstance;

@property (nonatomic,retain) OBATripDetailsV2 * tripDetails;
@property (nonatomic,retain) NSString * currentStopId;

@end
