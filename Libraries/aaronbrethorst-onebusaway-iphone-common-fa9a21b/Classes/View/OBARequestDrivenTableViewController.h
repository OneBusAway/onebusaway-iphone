#import "OBAApplicationDelegate.h"
#import "OBAProgressIndicatorView.h"


@interface OBARequestDrivenTableViewController : UITableViewController <OBAModelServiceDelegate> {
    OBAApplicationDelegate * _appContext;
    id<OBAModelServiceRequest> _request;
    OBAProgressIndicatorView * _progressView;
    NSString * _progressLabel;
    BOOL _showUpdateTime;
    BOOL _refreshable;
    NSInteger _refreshInterval;    
    
    NSTimer * _timer;
}

- (id) initWithApplicationContext:(OBAApplicationDelegate*)appContext;

@property (nonatomic,strong) IBOutlet OBAApplicationDelegate * appContext;

@property (nonatomic,strong) NSString * progressLabel;
@property (nonatomic) BOOL showUpdateTime;

@property (nonatomic) BOOL refreshable;
@property (nonatomic) NSInteger refreshInterval;

- (BOOL) isLoading;
- (void) refresh;

- (id<OBAModelServiceRequest>) handleRefresh;
- (void) handleData:(id)obj context:(id)context;
- (void) handleDataChanged;

@end
