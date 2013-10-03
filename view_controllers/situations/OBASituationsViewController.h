#import "OBAApplicationDelegate.h"


@interface OBASituationsViewController : UITableViewController {
    OBAApplicationDelegate * _appDelegate;
    NSArray * _situations;
}

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate situations:(NSArray*)situations;

@property (nonatomic,strong) NSDictionary * args;

@end
