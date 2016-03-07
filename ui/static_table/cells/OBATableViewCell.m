//
//  OBATableViewCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATableViewCell.h"

@implementation OBATableViewCell
@synthesize tableRow = _tableRow;

- (void)prepareForReuse {
    [super prepareForReuse];

    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.imageView.image = nil;
}

- (void)setTableRow:(OBATableRow *)tableRow
{
    OBAGuardClass(tableRow, OBATableRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.textLabel.text = _tableRow.title;
    self.textLabel.textAlignment = _tableRow.textAlignment;
    self.detailTextLabel.text = _tableRow.subtitle;
    self.accessoryType = _tableRow.accessoryType;
    self.imageView.image = _tableRow.image;
}
@end
