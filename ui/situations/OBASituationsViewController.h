NS_ASSUME_NONNULL_BEGIN

@interface OBASituationsViewController : UITableViewController {
    NSArray * _situations;
}
@property (nonatomic,strong,nullable) NSDictionary * args;

+ (void)showSituations:(NSArray*)situations navigationController:(UINavigationController*)navController args:(nullable NSDictionary*)args;
- (instancetype)initWithSituations:(NSArray*)situations;
@end

NS_ASSUME_NONNULL_END