//
//  OBABookmarkedRouteErrorCell.m
//  OBAKit
//
//  Created by Aaron Brethorst on 2/3/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBABookmarkedRouteErrorCell.h>
#import <OBAKit/OBATableRow.h>
#import <OBAKit/OBABookmarkedRouteRow.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBATheme.h>
@import Masonry;

@interface OBABookmarkedRouteErrorCell ()
@property(nonatomic,strong) UILabel *topLabel;
@property(nonatomic,strong) UILabel *errorLabel;
@property(nonatomic,copy,readonly) OBABookmarkedRouteRow *tableDataRow;
@end

@implementation OBABookmarkedRouteErrorCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        _topLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _topLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _topLabel.font = OBATheme.boldBodyFont;

        _errorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _errorLabel.numberOfLines = 0;
        _errorLabel.font = OBATheme.bodyFont;
        _errorLabel.translatesAutoresizingMaskIntoConstraints = NO;

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_topLabel, _errorLabel, [UIView new]]];
        stack.axis = UILayoutConstraintAxisVertical;
        [self.contentView addSubview:stack];
        [stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(OBATheme.defaultEdgeInsets);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.topLabel.text = nil;
    self.errorLabel.text = nil;
}

- (void)setTableRow:(OBATableRow *)tableRow {
    OBAGuardClass(tableRow, OBABookmarkedRouteRow) else {
        return;
    }
    _tableRow = [tableRow copy];

    self.topLabel.attributedText = self.tableDataRow.attributedTopLine ?: self.tableDataRow.attributedMiddleLine;
    self.errorLabel.text = self.tableDataRow.errorMessage;
}

- (OBABookmarkedRouteRow*)tableDataRow {
    return (OBABookmarkedRouteRow*)self.tableRow;
}

@end
