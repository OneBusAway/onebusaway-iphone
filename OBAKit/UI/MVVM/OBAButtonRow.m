//
//  OBAButtonRow.m
//  OBAKit
//
//  Created by Aaron Brethorst on 8/4/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAButtonRow.h>
#import <OBAKit/OBABaseTableCell.h>
#import <OBAKit/OBAViewModelRegistry.h>
#import <OBAKit/OBAKit-Swift.h>
@import Masonry;

@interface OBAButtonCell : OBABaseTableCell
@property(nonatomic,strong) OBABorderedButton *borderedButton;
@end

@implementation OBAButtonCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _borderedButton = [[OBABorderedButton alloc] initWithBorderColor:UIColor.blackColor title:@"Click me"];
        _borderedButton.titleLabel.font = [OBATheme boldFootnoteFont];
        [_borderedButton addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_borderedButton];
        [_borderedButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView);
            make.top.and.bottom.equalTo(self.contentView).insets(UIEdgeInsetsMake(OBATheme.defaultPadding, 0, OBATheme.defaultPadding, 0));
        }];
    }
    return self;
}

- (void)setTableRow:(OBABaseRow *)tableRow {
    OBAGuard([tableRow isKindOfClass:OBAButtonRow.class]) else {
        return;
    }

    _tableRow = [tableRow copy];

    [self.borderedButton setTitle:self.buttonRow.title forState:UIControlStateNormal];
    self.borderedButton.borderColor = self.buttonRow.buttonColor;
}

- (OBAButtonRow*)buttonRow {
    return (OBAButtonRow*)self.tableRow;
}

- (void)buttonTapped {
    self.tableRow.action((OBABaseRow*)self);
}

@end

@implementation OBAButtonRow

- (instancetype)initWithTitle:(NSString*)title action:(nullable OBARowAction)action {
    self = [super initWithAction:action];

    if (self) {
        _title = [title copy];
        _buttonColor = [OBATheme OBADarkGreen];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OBAButtonRow *row = [super copyWithZone:zone];
    row->_buttonColor = [_buttonColor copyWithZone:zone];
    row->_title = [_title copyWithZone:zone];

    return row;
}

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBAButtonCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

- (NSString*)cellReuseIdentifier {
    return NSStringFromClass(self.class);
}

@end
