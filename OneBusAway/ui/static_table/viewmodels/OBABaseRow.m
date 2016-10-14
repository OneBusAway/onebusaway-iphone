//
//  OBABaseRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/22/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"
#import "OBAViewModelRegistry.h"

@implementation OBABaseRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (instancetype)init {
    return [self initWithAction:nil];
}

- (instancetype)initWithAction:(void (^)(OBABaseRow *row))action {
    self = [super init];
    
    if (self) {
        _action = [action copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OBABaseRow *newRow = [[self.class allocWithZone:zone] init];
    newRow->_action = [_action copyWithZone:zone];
    newRow->_editAction = [_editAction copyWithZone:zone];
    newRow->_deleteModel = [_deleteModel copyWithZone:zone];
    newRow->_indentationLevel = _indentationLevel;
    newRow->_accessoryType = _accessoryType;
    newRow->_model = _model;
    newRow->_dataKey = [_dataKey copyWithZone:zone];
    newRow->_cellReuseIdentifier = [_cellReuseIdentifier copyWithZone:zone];

    return newRow;
}

#pragma mark - Public

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    // no-op.
}

+ (NSString*)cellReuseIdentifier {
    return NSStringFromClass(self.class);
}

- (NSString*)cellReuseIdentifier {
    if (!_cellReuseIdentifier) {
        _cellReuseIdentifier = [self.class cellReuseIdentifier];
    }
    return _cellReuseIdentifier;
}

@end
