//
//  OBAStaticTableViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBAStaticTableViewController.h"
#import "OBATableCell.h"
#import "OBAViewModelRegistry.h"

@interface OBAStaticTableViewController ()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong,readwrite) UITableView *tableView;
@end

@implementation OBAStaticTableViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        _tableView = ({
            UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero];
            tv.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
            tv.delegate = self;
            tv.dataSource = self;
            tv;
        });
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSArray *registered = [OBAViewModelRegistry registeredClasses];

    for (Class c in registered) {
        [c registerViewsWithTableView:self.tableView];
    }

    [self.view addSubview:self.tableView];
}

#pragma mark - UITableView Section Headers

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    UIView *headerView = [self tableView:tableView viewForHeaderInSection:section];

    if (headerView) {
        return CGRectGetHeight(headerView.frame);
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return self.sections[section].headerView;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section].title;
}

#pragma mark - UITableView Section Footers

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    UIView *footerView = [self tableView:tableView viewForFooterInSection:section];

    if (footerView) {
        return CGRectGetHeight(footerView.frame);
    }
    else {
        return 0.f;
    }
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return self.sections[section].footerView;
}

#pragma mark - UITableView

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    OBATableSection *section = self.sections[sectionIndex];
    return section.rows.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OBATableSection *section = self.sections[indexPath.section];
    OBATableRow *row = section.rows[indexPath.row];
    NSString *reuseIdentifier = [row.class cellReuseIdentifier];

    UITableViewCell<OBATableCell> *cell = (UITableViewCell<OBATableCell> *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

    OBAGuard([cell conformsToProtocol:@protocol(OBATableCell)]) else {
        return nil;
    }

    cell.tableRow = row;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OBATableSection *section = self.sections[indexPath.section];
    OBATableRow *row = section.rows[indexPath.row];

    if (row.action) {
        row.action();
    }
}
@end
