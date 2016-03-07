//
//  OBATableRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBATableRow.h"
#import "OBAViewModelRegistry.h"
#import "OBATableViewCell.h"

@implementation OBATableRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

+ (instancetype)tableRowWithTitle:(NSString*)title action:(void (^)())action {
    return [[self alloc] initWithTitle:title action:action];
}

- (instancetype)initWithTitle:(NSString*)title action:(void (^)())action {
    self = [super initWithAction:action];
    
    if (self) {
        _title = [title copy];
        _textAlignment = NSTextAlignmentLeft;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OBATableRow *newRow = [[self.class allocWithZone:zone] init];
    newRow->_title = [_title copyWithZone:zone];
    newRow->_subtitle = [_subtitle copyWithZone:zone];
    newRow->_style = _style;
    newRow->_accessoryType = _accessoryType;
    newRow->_image = _image;
    newRow->_textAlignment = _textAlignment;

    return newRow;
}

#pragma mark - Public

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBATableViewCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

+ (NSString*)cellReuseIdentifier {
    return NSStringFromClass(self.class);
}
@end
