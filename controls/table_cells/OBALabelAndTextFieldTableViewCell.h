@interface OBALabelAndTextFieldTableViewCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel * label;
@property (nonatomic,strong) IBOutlet UITextField * textField;

+ (OBALabelAndTextFieldTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView;

@end