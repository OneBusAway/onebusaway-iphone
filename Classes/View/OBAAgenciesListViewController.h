#import "OBAApplicationContext.h"
#import "OBARequestDrivenTableViewController.h"
#import "OBAArrivalAndDepartureV2.h"
#import "OBAArrivalAndDepartureInstanceRef.h"
#import "OBAArrivalEntryTableViewCellFactory.h"


@interface OBAAgenciesListViewController : OBARequestDrivenTableViewController {
	NSMutableArray * _agencies;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext;

@end
