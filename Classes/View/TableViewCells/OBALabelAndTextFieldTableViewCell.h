@interface OBALabelAndTextFieldTableViewCell : UITableViewCell {
	UILabel * _label;
	UITextField * _textField;
}

@property (nonatomic,strong) IBOutlet UILabel * label;
@property (nonatomic,strong) IBOutlet UITextField * textField;

+ (OBALabelAndTextFieldTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView;

@end