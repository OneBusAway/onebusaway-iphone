#import "OBAApplicationContext.h"
#import "OBARequestDrivenTableViewController.h"
#import "OBAVehicleStatusV2.h"


@interface OBAVehicleDetailsController : OBARequestDrivenTableViewController {
	NSString * _vehicleId;
	OBAVehicleStatusV2 * _vehicleStatus;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext vehicleId:(NSString*)vehicleId;


@end
