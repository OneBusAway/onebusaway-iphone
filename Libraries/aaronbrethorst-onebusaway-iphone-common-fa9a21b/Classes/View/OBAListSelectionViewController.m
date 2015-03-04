#import "OBAListSelectionViewController.h"
#import "UITableViewController+oba_Additions.h"
#import "OBAAnalytics.h"

@interface OBAListSelectionViewController ()
@property (nonatomic) NSArray *values;

@end

@implementation OBAListSelectionViewController

#pragma mark Initialization

- (id)initWithValues:(NSArray*)values selectedIndex:(NSIndexPath*)selectedIndex {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.values = values;
        self.checkedItem = selectedIndex;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self hideEmptySeparators];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [OBAAnalytics reportScreenView:[NSString stringWithFormat:@"View: %@", [self class]]];
}

#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.values.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = [self checkedItem].row == indexPath.row ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.textLabel.text = _values[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[tableView cellForRowAtIndexPath:self.checkedItem] setAccessoryType:UITableViewCellAccessoryNone];
    [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    self.checkedItem = indexPath;
    
    if([self.delegate respondsToSelector:@selector(checkItemWithIndex:)]) {
        [self.delegate checkItemWithIndex:indexPath];
    }
    
    if (self.exitOnSelection) {
        [self.navigationController popViewControllerAnimated:YES];
    }                                 
}


@end

