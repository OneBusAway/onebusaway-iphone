#import "OBAApplicationDelegate.h"
#import "OBARequestDrivenTableViewController.h"
#import "OBAVehicleStatusV2.h"


@interface OBAVehicleDetailsController : OBARequestDrivenTableViewController

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate vehicleId:(NSString*)vehicleId;


@end
