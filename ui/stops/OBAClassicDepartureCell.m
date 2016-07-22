//
//  OBAClassicDepartureCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAClassicDepartureCell.h"
#import <Masonry/Masonry.h>
#import "OBAClassicDepartureRow.h"
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

    self.departureView.routeNameLabel.text = nil;
    self.departureView.destinationLabel.text = nil;
    self.departureView.timeAndStatusLabel.text = nil;
    self.departureView.minutesUntilDepartureLabel.text = nil;
}

#pragma mark - OBATableCell

- (void)setTableRow:(OBABaseRow *)tableRow {

    OBAGuardClass(tableRow, OBAClassicDepartureRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.accessoryType = [self classicDepartureRow].accessoryType;

    self.departureView.classicDepartureRow = [self classicDepartureRow];
}

- (OBAClassicDepartureRow*)classicDepartureRow {
    return (OBAClassicDepartureRow*)[self tableRow];
}

@end
