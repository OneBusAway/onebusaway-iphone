//
//  OBATableViewCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBATableViewCell.h>
#import <OBAKit/OBATableRow.h>
#import <OBAKit/OBAMacros.h>

@implementation OBATableViewCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.textLabel.numberOfLines = 0;
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.textLabel.font = nil;
    self.textLabel.text = nil;
    self.textLabel.textColor = nil;
    self.detailTextLabel.text = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.imageView.image = nil;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
}

- (void)setTableRow:(OBATableRow *)tableRow
{
    OBAGuardClass(tableRow, OBATableRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.textLabel.font = [self tableDataRow].titleFont;

    if ([self tableDataRow].attributedTitle) {
        self.textLabel.attributedText = [self tableDataRow].attributedTitle;
    }
    else {
        self.textLabel.text = [self tableDataRow].title;
    }
    self.textLabel.textColor = [self tableDataRow].titleColor;
    self.textLabel.textAlignment = [self tableDataRow].textAlignment;
    self.detailTextLabel.text = [self tableDataRow].subtitle;
    self.accessoryType = [self tableDataRow].accessoryType;
    self.imageView.image = [self tableDataRow].image;
    self.selectionStyle = [self tableDataRow].selectionStyle;
    self.accessoryView = [self tableDataRow].accessoryView;
}

- (OBATableRow*)tableDataRow {
    return (OBATableRow*)self.tableRow;
}
@end


@implementation OBATableViewCellValue1
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    return self;
}
@end

@implementation OBATableViewCellValue2
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:reuseIdentifier];
    return self;
}
@end

@implementation OBATableViewCellSubtitle
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    return self;
}
@end
