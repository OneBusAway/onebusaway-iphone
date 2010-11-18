#import "OBAApplicationContext.h"
#import "OBANavigationTargetAware.h"
#import "OBATripDetailsV2.h"
#import "OBAProgressIndicatorView.h"


@interface OBAArrivalAndDepartureViewController : UITableViewController {
	OBAApplicationContext * _appContext;
	OBAArrivalAndDepartureV2 * _arrivalAndDeparture;
	NSUInteger _unreadServiceAlertCount;
	NSUInteger _serviceAlertCount;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext arrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;


@end
