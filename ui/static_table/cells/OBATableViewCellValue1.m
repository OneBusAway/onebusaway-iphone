//
//  OBATableViewCellValue1.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/4/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATableViewCellValue1.h"
#import "OBATableRow.h"
#import <OBAKit/OBAKit.h>
#import <Masonry/Masonry.h>

@interface OBATableViewCellValue1 ()
@property(nonatomic,strong) UILabel *obaTextLabel;
@property(nonatomic,strong) UILabel *obaDetailTextLabel;
@property(nonatomic,strong) UIStackView *stackView;
@end

@implementation OBATableViewCellValue1
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];

    if (self) {
        _obaTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _obaTextLabel.numberOfLines = 0;
        [_obaTextLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_obaTextLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _obaDetailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _obaDetailTextLabel.textColor = [UIColor darkGrayColor];
        [_obaDetailTextLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        // stack views seem to require spacing views for some scenarios, like ours. Lame.
        UIView *stupidSpacingView = [[UIView alloc] initWithFrame:CGRectZero];

        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_obaTextLabel, stupidSpacingView, _obaDetailTextLabel]];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentFill;
        _stackView.spacing = [OBATheme defaultPadding];
        _stackView.layoutMargins = self.layoutMargins;
        _stackView.layoutMarginsRelativeArrangement = YES;
        [self.contentView addSubview:_stackView];
        [_stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
            make.height.greaterThanOrEqualTo(@44);
        }];
    }

    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.textLabel.text = nil;
    self.textLabel.textColor = nil;
    self.detailTextLabel.text = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.imageView.image = nil;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
}

- (void)setTableRow:(OBATableRow *)tableRow {
    // this method very intentionally doesn't call super.

    OBAGuardClass(tableRow, OBATableRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.obaTextLabel.text = [self tableDataRow].title;
    self.obaTextLabel.textColor = [self tableDataRow].titleColor;
    self.obaTextLabel.textAlignment = [self tableDataRow].textAlignment;
    self.obaDetailTextLabel.text = [self tableDataRow].subtitle;
    self.accessoryType = [self tableDataRow].accessoryType;
    self.imageView.image = [self tableDataRow].image;
    self.selectionStyle = [self tableDataRow].selectionStyle;
}

- (OBATableRow*)tableDataRow {
    return (OBATableRow*)self.tableRow;
}

@end
