#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBALabelAndSwitchTableViewCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel * label;
@property (nonatomic,strong) IBOutlet UISwitch * toggleSwitch;

+ (OBALabelAndSwitchTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView;

@end

NS_ASSUME_NONNULL_END