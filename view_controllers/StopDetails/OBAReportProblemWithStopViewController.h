#import "OBAApplicationDelegate.h"
#import "OBAStopV2.h"
#import "OBAModalActivityIndicator.h"
#import "OBATextEditViewController.h"
#import "OBAListSelectionViewController.h"

@interface OBAReportProblemWithStopViewController : UITableViewController <UITextFieldDelegate,OBAModelServiceDelegate, OBATextEditViewControllerDelegate, OBAListSelectionViewControllerDelegate, UIAlertViewDelegate> {
    OBAApplicationDelegate * _appDelegate;
    OBAStopV2 * _stop;
    NSMutableArray * _problemIds;
    NSMutableArray * _problemNames;
    NSUInteger _problemIndex;
    NSString * _comment;
    
    OBAModalActivityIndicator * _activityIndicatorView;
}

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate stop:(OBAStopV2*)stop;

@end
