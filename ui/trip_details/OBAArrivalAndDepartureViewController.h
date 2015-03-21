#import "OBAApplicationDelegate.h"
#import "OBARequestDrivenTableViewController.h"
#import "OBAArrivalAndDepartureV2.h"
#import "OBAArrivalAndDepartureInstanceRef.h"
#import "OBAArrivalEntryTableViewCellFactory.h"


@interface OBAArrivalAndDepartureViewController : OBARequestDrivenTableViewController 

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate arrivalAndDepartureInstance:(OBAArrivalAndDepartureInstanceRef*)instance;
- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate arrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;


@end
