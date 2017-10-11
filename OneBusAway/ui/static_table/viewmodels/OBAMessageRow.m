//
//  OBAMessageRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/22/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBAMessageRow.h"
#import "OBAMessageCell.h"

@implementation OBAMessageRow

- (id)copyWithZone:(NSZone *)zone {
    OBAMessageRow *newRow = [super copyWithZone:zone];
    newRow->_sender = [_sender copyWithZone:zone];
    newRow->_subject = [_subject copyWithZone:zone];
    newRow->_date = [_date copyWithZone:zone];
    newRow->_unread = _unread;
    newRow->_highPriority = _highPriority;

    return newRow;
}

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBAMessageCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

- (NSString*)cellReuseIdentifier {
    return NSStringFromClass(self.class);
}

@end
