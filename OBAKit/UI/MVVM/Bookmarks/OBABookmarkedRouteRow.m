//
//  OBABookmarkedRouteRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBABookmarkedRouteRow.h>
#import <OBAKit/OBABookmarkedRouteCell.h>
#import <OBAKit/OBAViewModelRegistry.h>

@implementation OBABookmarkedRouteRow

- (instancetype)initWithBookmark:(OBABookmarkV2*)bookmark action:(nullable OBARowAction)action {
    self = [super initWithAction:action];

    if (self) {
        _bookmark = [bookmark copy];
        self.model = _bookmark;
    }

    return self;
}

#pragma mark - Base Row

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

- (id)copyWithZone:(NSZone *)zone {
    OBABookmarkedRouteRow *row = [super copyWithZone:zone];
    row->_bookmark = [_bookmark copyWithZone:zone];
    row->_supplementaryMessage = [_supplementaryMessage copyWithZone:zone];
    row->_state = _state;

    return row;
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBABookmarkedRouteCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

@end
