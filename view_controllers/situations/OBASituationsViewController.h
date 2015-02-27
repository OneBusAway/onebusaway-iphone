#import "OBAApplicationDelegate.h"


@interface OBASituationsViewController : UITableViewController {
    OBAApplicationDelegate * _appDelegate;
    NSArray * _situations;
}
@property (nonatomic,strong) NSDictionary * args;

- (instancetype) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate situations:(NSArray*)situations;


@end
