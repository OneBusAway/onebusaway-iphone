//
//  OBABookmarkedRouteCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBABookmarkedRouteCell.h>
#import <OBAKit/OBABookmarkedRouteRow.h>
#import <OBAKit/OBAClassicDepartureView.h>
#import <OBAKit/OBATableRow.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/OBAUIBuilder.h>
#import <OBAKit/OBAMacros.h>

@import Masonry;

@interface OBABookmarkedRouteCell ()
@property(nonatomic,strong,readwrite) OBAClassicDepartureView *departureView;
@end

@implementation OBABookmarkedRouteCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        _departureView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
        _departureView.contextMenuButton.hidden = YES;
        [self.contentView addSubview:_departureView];

        [_departureView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(OBATheme.defaultEdgeInsets);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self.departureView prepareForReuse];
}

- (void)setTableRow:(OBATableRow *)tableRow {
    OBAGuardClass(tableRow, OBABookmarkedRouteRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.departureView.departureRow = [self tableDataRow];
}

- (OBABookmarkedRouteRow*)tableDataRow {
    return (OBABookmarkedRouteRow*)self.tableRow;
}

@end
