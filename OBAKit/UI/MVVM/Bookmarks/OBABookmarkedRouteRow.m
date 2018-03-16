//
//  OBABookmarkedRouteRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBABookmarkedRouteRow.h>
#import <OBAKit/OBABookmarkedRouteCell.h>
#import <OBAKit/OBABookmarkedRouteLoadingCell.h>
#import <OBAKit/OBABookmarkedRouteErrorCell.h>
#import <OBAKit/OBAViewModelRegistry.h>
#import <OBAKit/NSObject+OBADescription.h>

static NSString * const OBABookmarkedRouteReuseIdentifierLoading = @"OBABookmarkedRouteReuseIdentifierLoading";
static NSString * const OBABookmarkedRouteReuseIdentifierError = @"OBABookmarkedRouteReuseIdentifierError";

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
    row->_errorMessage = [_errorMessage copyWithZone:zone];
    row->_state = _state;

    return row;
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBABookmarkedRouteCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
    [tableView registerClass:[OBABookmarkedRouteLoadingCell class] forCellReuseIdentifier:OBABookmarkedRouteReuseIdentifierLoading];
    [tableView registerClass:[OBABookmarkedRouteErrorCell class] forCellReuseIdentifier:OBABookmarkedRouteReuseIdentifierError];
}

- (NSString*)cellReuseIdentifier {
    if (self.upcomingDepartures.count > 0) {
        return [self.class cellReuseIdentifier];
    }
    else if (self.state == OBABookmarkedRouteRowStateLoading) {
        return OBABookmarkedRouteReuseIdentifierLoading;
    }
    else {
        return OBABookmarkedRouteReuseIdentifierError;
    }
}

- (NSString*)description {
    return [self oba_description:@[@"bookmark", @"attributedTopLine", @"attributedMiddleLine", @"attributedBottomLine"]];
}

@end
