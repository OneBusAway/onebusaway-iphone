/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAListSelectionViewController.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"
@import OBAKit;

@interface OBAListSelectionViewController ()
@property (nonatomic) NSArray *values;

@end

@implementation OBAListSelectionViewController

#pragma mark - Initialization

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
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor whiteColor];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.values.count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"identifier"];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [OBATheme bodyFont];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
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

