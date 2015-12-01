#import "OBAApplicationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBASituationsViewController : UITableViewController {
    OBAApplicationDelegate * _appDelegate;
    NSArray * _situations;
}
@property (nonatomic,strong,nullable) NSDictionary * args;

+ (void)showSituations:(NSArray*)situations withappDelegate:(OBAApplicationDelegate*)appDelegate navigationController:(UINavigationController*)navController args:(nullable NSDictionary*)args;
- (instancetype)initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate situations:(NSArray*)situations;
@end

NS_ASSUME_NONNULL_END