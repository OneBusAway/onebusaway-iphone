#import "OBAListSelectionViewController.h"
#import "OBAUITableViewCell.h"


@implementation OBAListSelectionViewController


#pragma mark Initialization

@synthesize checkedItem = _checkedItem;
@synthesize target = _target;
@synthesize action = _action;

- (id)initWithValues:(NSArray*)values selectedIndex:(NSIndexPath*)selectedIndex {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
		_values = [values retain];
		_checkedItem = [selectedIndex retain];
    }
    return self;
}

- (void)dealloc {
	[_values release];
	[_checkedItem release];
    [super dealloc];
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
	cell.textLabel.text = [_values objectAtIndex:indexPath.row];
	
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
								 
}


@end

