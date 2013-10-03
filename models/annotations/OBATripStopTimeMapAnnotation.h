#import "OBATripDetailsV2.h"
#import "OBATripStopTimeV2.h"


@interface OBATripStopTimeMapAnnotation : NSObject <MKAnnotation> {
    OBATripDetailsV2 * _tripDetails;
}

- (id) initWithTripDetails:(OBATripDetailsV2*)tripDetails stopTime:(OBATripStopTimeV2*)stopTime;

@property (nonatomic,strong) NSDateFormatter * timeFormatter;
@property (nonatomic,strong) OBATripStopTimeV2 * stopTime;

@end
