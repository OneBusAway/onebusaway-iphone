@interface OBAListSelectionViewController : UITableViewController {
	NSArray * _values;
	NSIndexPath * _checkedItem;
	id __weak _target;
	SEL _action;
}

@property (nonatomic,strong) NSIndexPath * checkedItem;
@property (nonatomic,weak) id target;
@property (nonatomic) SEL action;

@property (nonatomic) BOOL exitOnSelection;

- (id)initWithValues:(NSArray*)values selectedIndex:(NSIndexPath*)selectedIndex;


@end
