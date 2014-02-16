#import "OBAApplicationDelegate.h"
#import "OBANavigationTargetAware.h"
#import "OBATripDetailsV2.h"
#import "OBATripInstanceRef.h"
#import "OBAProgressIndicatorView.h"
#import "OBARequestDrivenTableViewController.h"

@interface OBATripDetailsViewController : OBARequestDrivenTableViewController <OBAModelServiceDelegate> {
    OBATripInstanceRef *_tripInstance;
    OBATripDetailsV2 *_tripDetails;
    OBAServiceAlertsModel *_serviceAlerts;
}

- (id)initWithApplicationDelegate:(OBAApplicationDelegate *)appDelegate tripInstance:(OBATripInstanceRef *)tripInstance;

@property (nonatomic, strong) OBATripInstanceRef *tripInstance;
@property (nonatomic, strong) OBATripDetailsV2 *tripDetails;
@property (nonatomic, strong) OBAServiceAlertsModel *serviceAlerts;
@property (nonatomic, strong) NSString *currentStopId;

@end
