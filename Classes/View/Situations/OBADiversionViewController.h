#import "OBAApplicationContext.h"
#import "OBATripDetailsV2.h"


@interface OBADiversionViewController : UIViewController <MKMapViewDelegate> {
	MKPolyline * _polyline;
	MKPolylineView * _polylineView;
}

+(OBADiversionViewController*) loadFromNibWithAppContext:(OBAApplicationContext*)context;

@property (nonatomic,retain) IBOutlet OBAApplicationContext * appContext;
@property (nonatomic,retain) NSString * diversionPath;

@end
