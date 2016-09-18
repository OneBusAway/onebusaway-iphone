#import <OBAKit/OBAKit.h>
#import "OBAModalActivityIndicator.h"
#import "OBATextEditViewController.h"
#import "OBAListSelectionViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAReportProblemWithTripViewController : UITableViewController <UITextFieldDelegate, OBATextEditViewControllerDelegate, OBAListSelectionViewControllerDelegate> {
    OBATripInstanceRef *_tripInstance;
    OBATripV2 *_trip;
    NSMutableArray *_problemIds;
    NSMutableArray *_problemNames;
    NSUInteger _problemIndex;
    NSString *_comment;
    BOOL _onVehicle;
    NSString *_vehicleNumber;
    NSString *_vehicleType;

    OBAModalActivityIndicator *_activityIndicatorView;
}

- (id)initWithTripInstance:(OBATripInstanceRef *)tripInstance trip:(OBATripV2 *)trip;

@property (nonatomic, strong) NSString *currentStopId;

@end

NS_ASSUME_NONNULL_END
