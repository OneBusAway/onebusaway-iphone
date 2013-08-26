#import "OBAApplicationDelegate.h"
#import "OBAProgressIndicatorView.h"
#import "UITableViewController+oba_Additions.h"

@interface OBARequestDrivenTableViewController : UITableViewController <OBAModelServiceDelegate> {
    OBAApplicationDelegate * _appDelegate;
    id<OBAModelServiceRequest> _request;
    OBAProgressIndicatorView * _progressView;
    NSString * _progressLabel;
    BOOL _showUpdateTime;
    BOOL _refreshable;
    NSInteger _refreshInterval;    
    
    NSTimer * _timer;
}

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate;

@property (nonatomic,strong) IBOutlet OBAApplicationDelegate * appDelegate;

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
