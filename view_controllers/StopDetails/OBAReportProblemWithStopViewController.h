#import "OBAApplicationDelegate.h"
#import "OBAStopV2.h"
#import "OBAModalActivityIndicator.h"
#import "OBATextEditViewController.h"

@interface OBAReportProblemWithStopViewController : UITableViewController <UITextFieldDelegate,OBAModelServiceDelegate, OBATextEditViewControllerDelegate> {
    OBAApplicationDelegate * _appContext;
    OBAStopV2 * _stop;
    NSMutableArray * _problemIds;
    NSMutableArray * _problemNames;
    NSUInteger _problemIndex;
    NSString * _comment;
    
    OBAModalActivityIndicator * _activityIndicatorView;
}

- (id) initWithApplicationContext:(OBAApplicationDelegate*)appContext stop:(OBAStopV2*)stop;

@end
