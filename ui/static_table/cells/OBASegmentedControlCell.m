//
//  OBASegmentedControlCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/12/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBASegmentedControlCell.h"
#import <Masonry/Masonry.h>
#import <OBAKit/OBAKit.h>
#import "OBASegmentedRow.h"

@interface OBASegmentedControlCell ()
@property(nonatomic,strong) UISegmentedControl *segmentedControl;
@end

@implementation OBASegmentedControlCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {

        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _segmentedControl = [[UISegmentedControl alloc] initWithFrame:self.contentView.bounds];
        [_segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [OBATheme textColor]} forState:UIControlStateNormal];
        [_segmentedControl addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.contentView addSubview:_segmentedControl];

        [_segmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets([self layoutMargins]);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self.segmentedControl removeAllSegments];
}

- (void)setTableRow:(OBABaseRow *)tableRow {
    OBAGuardClass(tableRow, OBASegmentedRow);
    _tableRow = [tableRow copy];

    for (NSUInteger i=0; i<[self segmentedRow].items.count; i++) {
        NSString *item = [self segmentedRow].items[i];
        [self.segmentedControl insertSegmentWithTitle:item atIndex:i animated:NO];
    }
    [self.segmentedControl setSelectedSegmentIndex:[self segmentedRow].selectedItemIndex];
}

- (OBASegmentedRow*)segmentedRow {
    return (OBASegmentedRow*)self.tableRow;
}

#pragma mark - Actions

- (void)valueChanged:(id)sender {

    if ([self segmentedRow].selectionChange) {
        [self segmentedRow].selectionChange(self.segmentedControl.selectedSegmentIndex);
    }
}

@end
