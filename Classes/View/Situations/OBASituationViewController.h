#import "OBAApplicationContext.h"
#import "OBASituationV2.h"


@interface OBASituationViewController : UITableViewController {
	OBAApplicationContext * _appContext;
	OBASituationV2 * _situation;
	NSString * _diversionPath;
}

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext situation:(OBASituationV2*)situation;

@property (nonatomic,retain) NSDictionary * args;

@end
