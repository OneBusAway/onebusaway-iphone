
NS_ASSUME_NONNULL_BEGIN

@protocol OBAListSelectionViewControllerDelegate <NSObject>
- (void) checkItemWithIndex:(NSIndexPath*)indexPath;
@end

@interface OBAListSelectionViewController : UITableViewController 

@property (nonatomic,strong) NSIndexPath *checkedItem;
@property (nonatomic) id<OBAListSelectionViewControllerDelegate> delegate;
@property (nonatomic) BOOL exitOnSelection;

- (id)initWithValues:(NSArray*)values selectedIndex:(NSIndexPath*)selectedIndex;

@end

NS_ASSUME_NONNULL_END