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

static NSString * const OBACellStyleDefaultReuseIdentifier = @"OBAUITableViewCellStyleDefaultCellIdentifier";
static NSString * const OBACellStyleValue1ReuseIdentifier = @"OBACellStyleValue1ReuseIdentifier";
static NSString * const OBACellStyleValue2ReuseIdentifier = @"OBACellStyleValue2ReuseIdentifier";
static NSString * const OBACellStyleSubtitleReuseIdentifier = @"OBACellStyleSubtitleReuseIdentifier";

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
    [tableView registerClass:[OBATableViewCell class] forCellReuseIdentifier:OBACellStyleDefaultReuseIdentifier];
    [tableView registerClass:[OBATableViewCellValue1 class] forCellReuseIdentifier:OBACellStyleValue1ReuseIdentifier];
    [tableView registerClass:[OBATableViewCellValue2 class] forCellReuseIdentifier:OBACellStyleValue2ReuseIdentifier];
    [tableView registerClass:[OBATableViewCellSubtitle class] forCellReuseIdentifier:OBACellStyleSubtitleReuseIdentifier];
}

- (NSString*)cellReuseIdentifier {
    switch (self.style) {
        case UITableViewCellStyleValue1:
            return OBACellStyleValue1ReuseIdentifier;
        case UITableViewCellStyleValue2:
            return OBACellStyleValue2ReuseIdentifier;
        case UITableViewCellStyleSubtitle:
            return OBACellStyleSubtitleReuseIdentifier;
        case UITableViewCellStyleDefault:
        default:
            return OBACellStyleDefaultReuseIdentifier;
    }
}
@end
