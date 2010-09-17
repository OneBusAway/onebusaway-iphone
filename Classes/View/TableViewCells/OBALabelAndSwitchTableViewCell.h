@interface OBALabelAndSwitchTableViewCell : UITableViewCell {
	UILabel * _label;
	UISwitch * _toggleSwitch;
}

@property (nonatomic,retain) IBOutlet UILabel * label;
@property (nonatomic,retain) IBOutlet UISwitch * toggleSwitch;

+ (OBALabelAndSwitchTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView;

@end
