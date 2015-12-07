//
//  OBAStaticTableViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBAStaticTableViewController.h"

@interface OBAStaticTableViewController ()<UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,strong,readwrite) UITableView *tableView;
@end

@implementation OBAStaticTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

#pragma mark - UITableView

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section].title;
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[row cellReuseIdentifier]];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:row.style reuseIdentifier:row.cellReuseIdentifier];
    }
    
    cell.textLabel.text = row.title;
    cell.detailTextLabel.text = row.subtitle;
    cell.accessoryType = row.accessoryType;
    
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
