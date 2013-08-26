#import "OBAApplicationDelegate.h"
#import "OBARequestDrivenTableViewController.h"
#import "OBAVehicleStatusV2.h"


@interface OBAVehicleDetailsController : OBARequestDrivenTableViewController {
    NSString * _vehicleId;
    OBAVehicleStatusV2 * _vehicleStatus;
}

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate vehicleId:(NSString*)vehicleId;


@end
