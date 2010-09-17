#import "OBAApplicationContext.h"
#import "OBATripDetailsV2.h"
#import "OBAModalActivityIndicator.h"


@interface OBAReportProblemWithTripViewController : UITableViewController <UITextFieldDelegate,OBAModelServiceDelegate> {
	OBAApplicationContext * _appContext;
	OBATripDetailsV2 * _tripDetails;
	NSMutableArray * _problemIds;
	NSMutableArray * _problemNames;
	NSUInteger _problemIndex;
	NSString * _comment;
	BOOL _onVehicle;
	NSString * _vehicleNumber;
	NSString * _vehicleType;
	
	OBAModalActivityIndicator * _activityIndicatorView;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext tripDetails:(OBATripDetailsV2*)tripDetails;

@property (nonatomic,retain) NSString * currentStopId;

@end
