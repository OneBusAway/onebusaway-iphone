//
//  OBARefreshRow.m
//  OBAKit
//
//  Created by Aaron Brethorst on 2/14/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBARefreshRow.h>
#import <OBAKit/OBARefreshCell.h>
#import <OBAKit/OBAViewModelRegistry.h>

@interface OBARefreshRow ()
@property(nonatomic,copy,readwrite) NSDate *date;
@end

@implementation OBARefreshRow

- (instancetype)initWithDate:(nullable NSDate*)date action:(nullable OBARowAction)action {
    self = [super initWithAction:action];

    if (self) {
        _date = [date copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OBARefreshRow *row = [super copyWithZone:zone];
    row->_date = [_date copyWithZone:zone];
    row->_rowState = _rowState;
    
    return row;
}

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBARefreshCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

- (NSString*)cellReuseIdentifier {
    return NSStringFromClass(self.class);
}

@end
