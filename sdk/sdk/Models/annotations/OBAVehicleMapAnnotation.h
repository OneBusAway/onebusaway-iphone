@import MapKit;
#import "OBATripStatusV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAVehicleMapAnnotation : NSObject <MKAnnotation> {
    OBATripStatusV2 * _tripStatus;
    BOOL _showLastKnownLocation;
}

- (id) initWithTripStatus:(OBATripStatusV2*)tripStatus;

@property (nonatomic) BOOL showLastKnownLocation;

@end

NS_ASSUME_NONNULL_END