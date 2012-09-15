#import "OBAApplicationContext.h"
#import "OBARequestDrivenTableViewController.h"
#import "OBAArrivalAndDepartureV2.h"
#import "OBAArrivalAndDepartureInstanceRef.h"
#import "OBAArrivalEntryTableViewCellFactory.h"


@interface OBAArrivalAndDepartureViewController : OBARequestDrivenTableViewController {
	OBAArrivalAndDepartureInstanceRef * _instance;
	OBAArrivalAndDepartureV2 * _arrivalAndDeparture;
	OBAArrivalEntryTableViewCellFactory * _arrivalCellFactory;
	OBAServiceAlertsModel * _serviceAlerts;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext arrivalAndDepartureInstance:(OBAArrivalAndDepartureInstanceRef*)instance;
- (id) initWithApplicationContext:(OBAApplicationContext*)appContext arrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;


@end
