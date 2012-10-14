#import "OBAApplicationDelegate.h"


@interface OBASituationsViewController : UITableViewController {
	OBAApplicationDelegate * _appContext;
	NSArray * _situations;
}

- (id) initWithApplicationContext:(OBAApplicationDelegate*)appContext situations:(NSArray*)situations;

@property (nonatomic,strong) NSDictionary * args;

@end
