#import "OBAApplicationDelegate.h"
#import "OBARequestDrivenTableViewController.h"
#import "OBAVehicleStatusV2.h"


@interface OBAVehicleDetailsController : OBARequestDrivenTableViewController {
    NSString * _vehicleId;
    OBAVehicleStatusV2 * _vehicleStatus;
}

- (id) initWithApplicationContext:(OBAApplicationDelegate*)appContext vehicleId:(NSString*)vehicleId;


@end
