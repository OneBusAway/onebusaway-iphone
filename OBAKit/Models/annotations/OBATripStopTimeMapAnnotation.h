#import <OBAKit/OBATripDetailsV2.h>
#import <OBAKit/OBATripStopTimeV2.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBATripStopTimeMapAnnotation : NSObject <MKAnnotation> {
    OBATripDetailsV2 * _tripDetails;
}

- (id) initWithTripDetails:(OBATripDetailsV2*)tripDetails stopTime:(OBATripStopTimeV2*)stopTime;

@property (nonatomic,strong) NSDateFormatter * timeFormatter;
@property (nonatomic,strong) OBATripStopTimeV2 * stopTime;

@end

NS_ASSUME_NONNULL_END
