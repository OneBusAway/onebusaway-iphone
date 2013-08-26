@interface OBALabelAndSwitchTableViewCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel * label;
@property (nonatomic,strong) IBOutlet UISwitch * toggleSwitch;

+ (OBALabelAndSwitchTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView;

@end
