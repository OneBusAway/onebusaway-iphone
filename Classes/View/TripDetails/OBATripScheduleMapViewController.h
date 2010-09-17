#import "OBAApplicationContext.h"
#import "OBATripDetailsV2.h"


@interface OBATripScheduleMapViewController : UIViewController <MKMapViewDelegate> {
	NSDateFormatter * _timeFormatter;
}

+(OBATripScheduleMapViewController*) loadFromNibWithAppContext:(OBAApplicationContext*)context;

@property (nonatomic,retain) IBOutlet OBAApplicationContext * appContext;
@property (nonatomic,retain) OBATripDetailsV2 * tripDetails;
@property (nonatomic,retain) NSString * currentStopId;

- (IBAction) showList:(id)source;

@end
