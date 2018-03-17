//
//  OBASwitchRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBASwitchRow.h"
#import "OBASwitchCell.h"

@implementation OBASwitchRow

- (instancetype)initWithTitle:(NSString*)title action:(nullable OBARowAction)action switchValue:(BOOL)switchValue {
    self = [super initWithTitle:title action:action];
    if (self) {
        _switchValue = switchValue;
    }
    return self;
}

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (id)copyWithZone:(NSZone *)zone {
    OBASwitchRow *row = [super copyWithZone:zone];
    row->_switchValue = _switchValue;

    return row;
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBASwitchCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

- (NSString*)cellReuseIdentifier {
    return NSStringFromClass(self.class);
}

@end
