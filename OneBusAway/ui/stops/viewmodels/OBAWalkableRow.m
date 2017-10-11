//
//  OBAWalkableRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 11/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAWalkableRow.h"
#import "OBAWalkableCell.h"

@implementation OBAWalkableRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (id)copyWithZone:(NSZone *)zone {
    OBAWalkableRow *row = [super copyWithZone:zone];
    row->_text = [_text copyWithZone:zone];
    return row;
}

+ (void)registerViewsWithTableView:(UITableView*)tableView {
    [tableView registerClass:[OBAWalkableCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

@end
