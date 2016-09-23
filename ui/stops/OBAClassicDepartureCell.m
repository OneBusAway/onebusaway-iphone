//
//  OBAClassicDepartureCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAClassicDepartureCell.h"
#import <Masonry/Masonry.h>
#import "OBADepartureRow.h"
#import "OBAClassicDepartureView.h"

@interface OBAClassicDepartureCell ()
@property(nonatomic,strong) OBAClassicDepartureView *departureView;
@end

@implementation OBAClassicDepartureCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        _departureView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_departureView];

        [_departureView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(self.layoutMargins);
        }];
    }

    return self;
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
