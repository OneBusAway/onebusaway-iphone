//
//  OBAInfoViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/17/12.
//
//

#import "OBAInfoViewController.h"

@implementation OBAInfoViewController

- (id)init {
    self = [super initWithNibName:@"OBAInfoViewController" bundle:nil];

    if (self) {
        //
    }
    return self;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"CellIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    if (0 == indexPath.row) {
        cell.textLabel.text = NSLocalizedString(@"Contact Us", @"");
    }
    else if (1 == indexPath.row) {
        cell.textLabel.text = NSLocalizedString(@"Settings", @"");
    }
    else if (2 == indexPath.row) {
        cell.textLabel.text = NSLocalizedString(@"Agencies", @"");
    }
    else {
        cell.textLabel.text = NSLocalizedString(@"Credits", @"");
    }

    return cell;
}

@end
