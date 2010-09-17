#import "OBAApplicationContext.h"
#import "OBATripDetailsV2.h"


@interface OBAReportAProblemViewController : UITableViewController <UITextFieldDelegate,OBAModelServiceDelegate> {
	OBAApplicationContext * _appContext;
	OBATripDetailsV2 * _tripDetails;
	NSArray * _problemNames;
	NSUInteger _problemIndex;
	NSString * _comment;
	BOOL _onVehicle;
	NSString * _vehicleNumber;
	NSString * _vehicleType;
	
	UIProgressView * _progressView;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext tripDetails:(OBATripDetailsV2*)tripDetails;

@property (nonatomic,retain) NSString * currentStopId;

@end
