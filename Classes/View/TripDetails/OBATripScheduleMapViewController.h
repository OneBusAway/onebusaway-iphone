#import "OBAApplicationContext.h"
#import "OBATripDetailsV2.h"
#import "OBATripInstanceRef.h"
#import "OBAProgressIndicatorView.h"


@interface OBATripScheduleMapViewController : UIViewController <MKMapViewDelegate,OBAModelServiceDelegate> {
	OBAApplicationContext * _appContext;
	OBATripInstanceRef * _tripInstance;
	NSString * _currentStopId;
	OBATripDetailsV2 * _tripDetails;
	id<OBAModelServiceRequest> _request;
	OBAProgressIndicatorView * _progressView;	
	NSDateFormatter * _timeFormatter;
	
	MKPolyline * _routePolyline;
	MKPolylineView * _routePolylineView;
}

+(OBATripScheduleMapViewController*) loadFromNibWithAppContext:(OBAApplicationContext*)context;

@property (nonatomic,retain) IBOutlet OBAApplicationContext * appContext;
@property (nonatomic,retain) IBOutlet OBAProgressIndicatorView * progressView;
@property (nonatomic,retain) OBATripInstanceRef * tripInstance;
@property (nonatomic,retain) OBATripDetailsV2 * tripDetails;
@property (nonatomic,retain) NSString * currentStopId;

- (IBAction) showList:(id)source;

@end
