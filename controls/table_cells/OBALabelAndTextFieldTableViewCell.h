
NS_ASSUME_NONNULL_BEGIN

@interface OBALabelAndTextFieldTableViewCell : UITableViewCell

@property (nonatomic,strong) IBOutlet UILabel * label;
@property (nonatomic,strong) IBOutlet UITextField * textField;

+ (OBALabelAndTextFieldTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView;

@end

NS_ASSUME_NONNULL_END