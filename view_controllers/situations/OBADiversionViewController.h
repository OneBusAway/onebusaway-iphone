#import "OBAApplicationContext.h"
#import "OBATripDetailsV2.h"


@interface OBADiversionViewController : UIViewController <MKMapViewDelegate,OBAModelServiceDelegate> {

	NSString * _tripEncodedPolyline;

	MKPolyline * _routePolyline;
	MKPolylineView * _routePolylineView;

	MKPolyline * _reroutePolyline;
	MKPolylineView * _reroutePolylineView;
	
	id<OBAModelServiceRequest> _request;
}

+(OBADiversionViewController*) loadFromNibWithAppContext:(OBAApplicationContext*)context;

@property (nonatomic,strong) IBOutlet OBAApplicationContext * appContext;
@property (nonatomic,strong) NSString * diversionPath;
@property (nonatomic,strong) NSDictionary * args;

@end
