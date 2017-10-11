//
//  OBASegmentedRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/12/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBASegmentedRow.h"
#import "OBASegmentedControlCell.h"

@implementation OBASegmentedRow

- (instancetype)initWithSelectionChange:(void(^)(NSUInteger selectedIndex))selectionChange {
    self = [super initWithAction:nil];

    if (self) {
        _selectionChange = [selectionChange copy];
    }
    return self;
}


+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (id)copyWithZone:(NSZone *)zone {
    OBASegmentedRow *row = [super copyWithZone:zone];
    row->_items = [_items copyWithZone:zone];
    row->_selectedItemIndex = _selectedItemIndex;
    row->_selectionChange = [_selectionChange copyWithZone:zone];

    return row;
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBASegmentedControlCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

@end
