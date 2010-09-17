#import "OBAApplicationContext.h"
#import "OBANavigationTargetAware.h"
#import "OBATripDetailsV2.h"
#import "OBAProgressIndicatorView.h"


@interface OBATripDetailsViewController : UITableViewController <OBANavigationTargetAware,OBAModelServiceDelegate> {
	OBAApplicationContext * _appContext;
	NSString * _tripId;
	OBATripDetailsV2 * _tripDetails;
	
	id<OBAModelServiceRequest> _request;
	
	OBAProgressIndicatorView * _progressView;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext tripId:(NSString*)tripId;

@property (nonatomic,retain) OBATripDetailsV2 * tripDetails;
@property (nonatomic,retain) NSString * currentStopId;

@end
