//
//  OBATableViewCellValue1.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/4/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATableViewCellValue1.h"
#import "OBATableRow.h"
@import OBAKit;
@import Masonry;

@interface OBATableViewCellValue1 ()
@property(nonatomic,strong) OBAValue1ContentsView *value1ContentsView;
@end

@implementation OBATableViewCellValue1
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];

    if (self) {
        _value1ContentsView = [[OBAValue1ContentsView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_value1ContentsView];
        [_value1ContentsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(0, 2 * [OBATheme defaultPadding], 0, [OBATheme defaultPadding]));
            make.height.greaterThanOrEqualTo(@44);
        }];
    }

    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    [self.value1ContentsView prepareForReuse];

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

    self.value1ContentsView.imageView.image = [self tableDataRow].image;
    self.value1ContentsView.imageView.hidden = ![self tableDataRow].image;

    self.value1ContentsView.textLabel.font = [self tableDataRow].titleFont;
    self.value1ContentsView.textLabel.text = [self tableDataRow].title;
    self.value1ContentsView.textLabel.textColor = [self tableDataRow].titleColor;
    self.value1ContentsView.textLabel.textAlignment = [self tableDataRow].textAlignment;

    self.value1ContentsView.detailTextLabel.text = [self tableDataRow].subtitle;

    self.accessoryType = [self tableDataRow].accessoryType;
    self.selectionStyle = [self tableDataRow].selectionStyle;
}

- (OBATableRow*)tableDataRow {
    return (OBATableRow*)self.tableRow;
}

@end
