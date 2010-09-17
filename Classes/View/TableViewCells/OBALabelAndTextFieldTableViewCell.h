@interface OBALabelAndTextFieldTableViewCell : UITableViewCell {
	UILabel * _label;
	UITextField * _textField;
}

@property (nonatomic,retain) IBOutlet UILabel * label;
@property (nonatomic,retain) IBOutlet UITextField * textField;

+ (OBALabelAndTextFieldTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView;

@end