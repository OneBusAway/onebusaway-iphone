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

+(OBADiversionViewController*) loadFromNibWithappDelegate:(OBAApplicationDelegate*)context;

@property (nonatomic,strong) IBOutlet OBAApplicationDelegate * appDelegate;
@property (nonatomic,strong) NSString * diversionPath;
@property (nonatomic,strong) NSDictionary * args;

@end
