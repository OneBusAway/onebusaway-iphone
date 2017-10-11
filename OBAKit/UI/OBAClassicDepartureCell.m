//
//  OBAClassicDepartureCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAClassicDepartureCell.h>
#import <OBAKit/OBADepartureRow.h>
#import <OBAKit/OBAClassicDepartureView.h>
#import <OBAKit/OBAMacros.h>
@import Masonry;

@interface OBAClassicDepartureCell ()
@property(nonatomic,strong) OBAClassicDepartureView *departureView;
@end

@implementation OBAClassicDepartureCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.contentView.clipsToBounds = YES;

        _departureView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_departureView];

        [_departureView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(self.layoutMargins);
        }];

        [_departureView.contextMenuButton addTarget:self action:@selector(showActionMenu:) forControlEvents:UIControlEventTouchUpInside];
    }

    return self;
}

#pragma mark - Context Menu

- (void)showActionMenu:(UIButton*)sender {
    if ([self departureRow].showAlertController) {
        [self departureRow].showAlertController(sender);
    }
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];

    [self.departureView prepareForReuse];
}

#pragma mark - OBATableCell

- (void)setTableRow:(OBABaseRow *)tableRow {
    OBAGuardClass(tableRow, OBADepartureRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.accessoryType = [self departureRow].accessoryType;

    self.departureView.departureRow = [self departureRow];
}

- (OBADepartureRow*)departureRow {
    return (OBADepartureRow*)[self tableRow];
}

@end
