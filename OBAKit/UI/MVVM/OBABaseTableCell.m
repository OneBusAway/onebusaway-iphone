//
//  OBABaseTableCell.m
//  OBAKit
//
//  Created by Aaron Brethorst on 2/3/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBABaseTableCell.h>

@implementation OBABaseTableCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.contentView.clipsToBounds = YES;
        self.contentView.frame = self.bounds;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

@end
