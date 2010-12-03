#import "OBAApplicationContext.h"
#import "OBATripDetailsV2.h"
#import "OBAModalActivityIndicator.h"
#import "OBATripInstanceRef.h"


@interface OBAReportProblemWithTripViewController : UITableViewController <UITextFieldDelegate,OBAModelServiceDelegate> {
	OBAApplicationContext * _appContext;
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

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext tripInstance:(OBATripInstanceRef*)tripInstance trip:(OBATripV2*)trip;

@property (nonatomic,retain) NSString * currentStopId;

@end
