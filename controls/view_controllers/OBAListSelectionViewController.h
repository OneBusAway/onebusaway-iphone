
@protocol OBAListSelectionViewControllerDelegate <NSObject>
- (void) checkItemWithIndex:(NSIndexPath*)indexPath;
@end


@interface OBAListSelectionViewController : UITableViewController 

@property (nonatomic,strong) NSIndexPath *checkedItem;
@property (nonatomic) id<OBAListSelectionViewControllerDelegate> delegate;
@property (nonatomic) BOOL exitOnSelection;

- (id)initWithValues:(NSArray*)values selectedIndex:(NSIndexPath*)selectedIndex;

@end
