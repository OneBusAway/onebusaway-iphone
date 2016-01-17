#import "OBASituationV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBASituationViewController : UITableViewController {
    OBASituationV2 * _situation;
    NSString * _diversionPath;
}

- (id) initWithSituation:(OBASituationV2*)situation;

@property (nonatomic,strong) NSDictionary * args;

@end

NS_ASSUME_NONNULL_END