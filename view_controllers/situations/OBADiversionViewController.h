#import "OBAApplicationDelegate.h"
#import "OBATripDetailsV2.h"


@interface OBADiversionViewController : UIViewController <MKMapViewDelegate,OBAModelServiceDelegate> {

    NSString * _tripEncodedPolyline;

    MKPolyline * _routePolyline;
    MKPolylineView * _routePolylineView;

    MKPolyline * _reroutePolyline;
    MKPolylineView * _reroutePolylineView;
    
    id<OBAModelServiceRequest> _request;
}

+(OBADiversionViewController*) loadFromNibWithAppContext:(OBAApplicationDelegate*)context;

@property (nonatomic,strong) IBOutlet OBAApplicationDelegate * appContext;
@property (nonatomic,strong) NSString * diversionPath;
@property (nonatomic,strong) NSDictionary * args;

@end
