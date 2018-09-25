//
//  OBAButtonBarRow.m
//  OBAKit
//
//  Created by Aaron Brethorst on 8/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAButtonBarRow.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBABaseTableCell.h>
#import <OBAKit/OBAViewModelRegistry.h>
#import <OBAKit/UIStackView+OBAAdditions.h>
#import <OBAKit/UIView+OBAAdditions.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/OBAKit-Swift.h>
@import Masonry;

@interface OBAButtonBarRowCell : OBABaseTableCell
@property(nonatomic,copy,readonly) OBAButtonBarRow *buttonRow;
@property(nonatomic,strong) UIStackView *buttonStack;
@end

@implementation OBAButtonBarRowCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;

        _buttonStack = [UIStackView oba_horizontalStackWithArrangedSubviews:@[]];
        _buttonStack.spacing = OBATheme.defaultPadding;
        _buttonStack.distribution = UIStackViewDistributionFillEqually;
        [self.contentView addSubview:_buttonStack];
        [_buttonStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(OBATheme.defaultEdgeInsets);
            make.height.lessThanOrEqualTo(@50);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    for (UIView *v in self.buttonStack.arrangedSubviews) {
        [self.buttonStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (void)setTableRow:(OBABaseRow *)tableRow {
    OBAGuard([tableRow isKindOfClass:OBAButtonBarRow.class]) else {
        return;
    }

    _tableRow = [tableRow copy];

    for (UIBarButtonItem *buttonItem in self.buttonRow.barButtonItems) {
        OBAStackedButton *button = [self newControlForBarButtonItem:buttonItem];

        if (button) {
            [self.buttonStack addArrangedSubview:button];
        }
    }
}

- (OBAButtonBarRow*)buttonRow {
    return (OBAButtonBarRow*)self.tableRow;
}

#pragma mark - UIBarButtonItems/Buttons/Actions

// Adapted from ISHHoverBar:
- (nullable OBAStackedButton*)newControlForBarButtonItem:(nonnull UIBarButtonItem *)item {
    if ([item.customView isKindOfClass:[UIControl class]]) {
        return item.customView;
    }

    if (!item.image && !item.title.length) {
        NSAssert(item.image || item.title.length,
                 @"ISHHoverBar only support bar button items with an image, title or customView (of type UIControl). "
                 @"If you attempted to use a system item, please consider creating your own artwork.");
        return nil;
    }

    OBAStackedButton *button = [OBAStackedButton oba_autolayoutNew];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@40).priorityHigh();
        make.width.greaterThanOrEqualTo(@40);
    }];

    button.imageView.image = item.image;
    button.textLabel.text = item.title;
    button.accessibilityLabel = item.accessibilityLabel;
    button.tintColor = UIColor.blackColor;

    [button addTarget:item.target action:item.action forControlEvents:UIControlEventTouchUpInside];

    return button;
}

@end

#pragma mark - Row

@implementation OBAButtonBarRow

- (instancetype)initWithBarButtonItems:(NSArray<UIBarButtonItem*>*)barButtonItems {
    self = [super initWithAction:nil];

    if (self) {
        _barButtonItems = [barButtonItems copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    OBAButtonBarRow *row = [super copyWithZone:zone];
    row->_barButtonItems = _barButtonItems;
    return row;
}

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBAButtonBarRowCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

- (NSString*)cellReuseIdentifier {
    return NSStringFromClass(self.class);
}

@end
