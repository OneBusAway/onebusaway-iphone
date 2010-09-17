#import "OBATripDetailsV2.h"
#import "OBATripStopTimeV2.h"


@interface OBATripStopTimeMapAnnotation : NSObject <MKAnnotation> {
	OBATripDetailsV2 * _tripDetails;
	OBATripStopTimeV2 * _stopTime;
}

- (id) initWithTripDetails:(OBATripDetailsV2*)tripDetails stopTime:(OBATripStopTimeV2*)stopTime;

@property (nonatomic,retain) NSDateFormatter * timeFormatter;
@property (nonatomic,retain) OBATripStopTimeV2 * stopTime;

@end
