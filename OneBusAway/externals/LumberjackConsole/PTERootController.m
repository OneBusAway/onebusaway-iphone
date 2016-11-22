//
//  PTERootController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/4/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "PTERootController.h"
@import OBAKit;

@interface PTERootController ()
@property(nonatomic,strong) UITableView *tableView;
@end

@implementation PTERootController

- (instancetype)init {
    self = [super initWithNibName:nil bundle:nil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"msg_logs",);

    self.view.backgroundColor = [UIColor blackColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.dataSource = [OBAApplication sharedApplication].consoleLogger;
    self.tableView.delegate = [OBAApplication sharedApplication].consoleLogger;
    self.tableView.allowsMultipleSelection = YES;
    self.tableView.rowHeight = 40.f;
    self.tableView.backgroundColor = self.view.backgroundColor;

    [self.view addSubview:self.tableView];

    self.toolbarItems = [self constructToolbarItems];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [OBAApplication sharedApplication].consoleLogger.tableView = self.tableView;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [OBAApplication sharedApplication].consoleLogger.tableView = nil;
}

- (NSArray<UIBarButtonItem*>*)constructToolbarItems {
    UIBarButtonItem *markBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"msg_mark",) style:UIBarButtonItemStylePlain target:self action:@selector(markConsole)];

    UIBarButtonItem *clearBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"msg_clear",) style:UIBarButtonItemStylePlain target:self action:@selector(clearConsole)];

    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    return @[markBarButtonItem, spacer, clearBarButtonItem];
}

#pragma mark - Actions

- (void)clearConsole {
    [[OBAApplication sharedApplication].consoleLogger clearConsole];
}

- (void)markConsole {
    [[OBAApplication sharedApplication].consoleLogger addMarker];
}

@end
