//
//  OBATextFieldRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/24/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATextFieldRow.h"
#import "OBAViewModelRegistry.h"
#import "OBATextFieldCell.h"

@implementation OBATextFieldRow

- (instancetype)initWithLabelText:(NSString*)labelText textFieldText:(NSString*)textFieldText {
    self = [super initWithAction:nil];
    if (self) {
        _labelText = [labelText copy];
        _textFieldText = [textFieldText copy];
    }
    return self;
}

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (id)copyWithZone:(NSZone *)zone {
    OBATextFieldRow *row = [super copyWithZone:zone];
    row->_textFieldText = [_textFieldText copyWithZone:zone];
    row->_labelText = [_labelText copyWithZone:zone];
    row->_keyboardType = _keyboardType;
    row->_autocapitalizationType = _autocapitalizationType;
    row->_autocorrectionType = _autocorrectionType;
    row->_returnKeyType = _returnKeyType;

    return row;
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBATextFieldCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

@end
