#import "OBATripDetailsV2.h"
#import "OBATripInstanceRef.h"
#import "OBAProgressIndicatorView.h"
#import "OBAModelServiceRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBATripScheduleListViewController : UITableViewController {
    OBATripInstanceRef *_tripInstance;
    OBATripDetailsV2 *_tripDetails;
    id<OBAModelServiceRequest> _request;
    BOOL _showPreviousStops;
    NSInteger _currentStopIndex;

    NSDateFormatter *_timeFormatter;
    OBAProgressIndicatorView *_progressView;
}

- (id)initWithTripInstance:(OBATripInstanceRef *)tripInstance;

@property (nonatomic, strong) OBATripDetailsV2 *tripDetails;
@property (nonatomic, strong) NSString *currentStopId;

@end

NS_ASSUME_NONNULL_END