#import "OBAApplicationDelegate.h"
#import "OBATripDetailsV2.h"
#import "OBATripInstanceRef.h"
#import "OBAProgressIndicatorView.h"


@interface OBATripScheduleMapViewController : UIViewController <MKMapViewDelegate> 

- (id)initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate;

@property (nonatomic,strong) OBAApplicationDelegate * appDelegate;
@property (nonatomic,strong) OBAProgressIndicatorView * progressView;
@property (nonatomic,strong) OBATripInstanceRef * tripInstance;
@property (nonatomic,strong) OBATripDetailsV2 * tripDetails;
@property (nonatomic,strong) NSString * currentStopId;

- (void) showList:(id)source;

@end
