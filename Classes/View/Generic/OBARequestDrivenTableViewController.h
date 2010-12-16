#import "OBAApplicationContext.h"
#import "OBAProgressIndicatorView.h"


@interface OBARequestDrivenTableViewController : UITableViewController <OBAModelServiceDelegate> {
	OBAApplicationContext * _appContext;
	id<OBAModelServiceRequest> _request;
	OBAProgressIndicatorView * _progressView;
	NSString * _progressLabel;
	BOOL _showUpdateTime;
	BOOL _refreshable;
	NSInteger _refreshInterval;	
	
	NSTimer * _timer;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext;

@property (nonatomic,retain) IBOutlet OBAApplicationContext * appContext;

@property (nonatomic,retain) NSString * progressLabel;
@property (nonatomic) BOOL showUpdateTime;

@property (nonatomic) BOOL refreshable;
@property (nonatomic) NSInteger refreshInterval;

- (BOOL) isLoading;
- (void) refresh;

- (id<OBAModelServiceRequest>) handleRefresh;
- (void) handleData:(id)obj context:(id)context;
- (void) handleDataChanged;

@end
