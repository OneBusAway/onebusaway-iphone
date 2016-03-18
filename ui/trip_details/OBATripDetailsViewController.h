#import "OBANavigationTargetAware.h"
#import "OBATripDetailsV2.h"
#import "OBATripInstanceRef.h"
#import "OBAProgressIndicatorView.h"
#import "OBARequestDrivenTableViewController.h"
#import "OBAServiceAlertsModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBATripDetailsViewController : OBARequestDrivenTableViewController {
    OBATripInstanceRef *_tripInstance;
    OBATripDetailsV2 *_tripDetails;
    OBAServiceAlertsModel *_serviceAlerts;
}

- (id)initWithTripInstance:(OBATripInstanceRef *)tripInstance;

@property (nonatomic, strong) OBATripInstanceRef *tripInstance;
@property (nonatomic, strong) OBATripDetailsV2 *tripDetails;
@property (nonatomic, strong) OBAServiceAlertsModel *serviceAlerts;
@property (nonatomic, strong) NSString *currentStopId;

@end

NS_ASSUME_NONNULL_END