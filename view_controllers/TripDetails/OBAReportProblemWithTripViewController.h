#import "OBAApplicationDelegate.h"
#import "OBATripDetailsV2.h"
#import "OBAModalActivityIndicator.h"
#import "OBATripInstanceRef.h"
#import "OBATextEditViewController.h"
#import "OBAListSelectionViewController.h"

@interface OBAReportProblemWithTripViewController : UITableViewController <UITextFieldDelegate,OBAModelServiceDelegate, OBATextEditViewControllerDelegate, OBAListSelectionViewControllerDelegate, UIAlertViewDelegate> {
    OBAApplicationDelegate * _appDelegate;
    OBATripInstanceRef * _tripInstance;
    OBATripV2 * _trip;
    NSMutableArray * _problemIds;
    NSMutableArray * _problemNames;
    NSUInteger _problemIndex;
    NSString * _comment;
    BOOL _onVehicle;
    NSString * _vehicleNumber;
    NSString * _vehicleType;
    
    OBAModalActivityIndicator * _activityIndicatorView;
}

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate tripInstance:(OBATripInstanceRef*)tripInstance trip:(OBATripV2*)trip;

@property (nonatomic,strong) NSString * currentStopId;

@end
