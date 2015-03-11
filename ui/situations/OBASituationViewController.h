#import "OBAApplicationDelegate.h"
#import "OBASituationV2.h"


@interface OBASituationViewController : UITableViewController {
    OBAApplicationDelegate * _appDelegate;
    OBASituationV2 * _situation;
    NSString * _diversionPath;
}

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate situation:(OBASituationV2*)situation;

@property (nonatomic,strong) NSDictionary * args;

@end
