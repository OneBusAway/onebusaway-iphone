#import "OBAListSelectionViewController.h"


@implementation OBAListSelectionViewController


#pragma mark Initialization

@synthesize checkedItem = _checkedItem;
@synthesize target = _target;
@synthesize action = _action;
@synthesize exitOnSelection;

- (id)initWithValues:(NSArray*)values selectedIndex:(NSIndexPath*)selectedIndex {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		_values = values;
		_checkedItem = selectedIndex;
    }
    return self;
}



#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_values count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.textLabel.textAlignment = UITextAlignmentLeft;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	cell.accessoryType = [self checkedItem] == indexPath ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.textLabel.text = _values[indexPath.row];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath == [self checkedItem]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    [[tableView cellForRowAtIndexPath:[self checkedItem]] setAccessoryType:UITableViewCellAccessoryNone];
    [self setCheckedItem:indexPath];
	
	if( _target && _action && [_target respondsToSelector:_action] )
		[_target performSelector:_action withObject:indexPath];
    
    if (self.exitOnSelection) {
        [self.navigationController popViewControllerAnimated:YES];
    }								 
}


@end

