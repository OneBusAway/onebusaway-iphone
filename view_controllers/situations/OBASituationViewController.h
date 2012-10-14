#import "OBAApplicationDelegate.h"
#import "OBASituationV2.h"


@interface OBASituationViewController : UITableViewController {
	OBAApplicationDelegate * _appContext;
	OBASituationV2 * _situation;
	NSString * _diversionPath;
}

- (id) initWithApplicationContext:(OBAApplicationDelegate*)appContext situation:(OBASituationV2*)situation;

@property (nonatomic,strong) NSDictionary * args;

@end
