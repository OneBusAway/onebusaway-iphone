#import "OBATripStatusV2.h"


@interface OBAVehicleMapAnnotation : NSObject <MKAnnotation> {
	OBATripStatusV2 * _tripStatus;
	BOOL _showLastKnownLocation;
}

- (id) initWithTripStatus:(OBATripStatusV2*)tripStatus;

@property (nonatomic) BOOL showLastKnownLocation;

@end
