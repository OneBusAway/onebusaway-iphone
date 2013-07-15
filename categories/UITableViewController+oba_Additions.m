//
//  UITableViewController+oba_Additions.m
//  org.onebusaway.iphone
//
//  Created by Sebastian Kießling on 06.06.13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import "UITableViewController+oba_Additions.h"

@implementation UITableViewController (oba_Additions)

- (void) hideEmptySeparators
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    footerView.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:footerView];
}
@end
