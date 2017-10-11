//
//  OBASwitchCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBASwitchCell.h"
#import "OBASwitchRow.h"

@interface OBASwitchCell ()
@property(nonatomic,strong) UISwitch *switchCtl;
@end

@implementation OBASwitchCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _switchCtl = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        [_switchCtl addTarget:self action:@selector(switchToggled) forControlEvents:UIControlEventValueChanged];
        self.accessoryView = _switchCtl;
    }
    return self;
}

#pragma mark - Action

- (void)switchToggled {
    OBASwitchRow *row = [self switchRow];

    if (row.action) {
        row.action(row);
    }

    NSMutableDictionary *dict = row.model;
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return;
    }

    // We rely on duck typing to ensure that we're not going to shoot
    // ourselves in the foot here, by muddling about in a class cluster.
    if (![dict respondsToSelector:@selector(setObject:forKeyedSubscript:)]) {
        return;
    }

    if (!row.dataKey) {
        return;
    }

    dict[row.dataKey] = @(self.switchCtl.on);
}

#pragma mark - OBATableCell

- (void)setTableRow:(OBABaseRow *)tableRow {
    OBAGuardClass(tableRow, OBASwitchRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.textLabel.text = [self switchRow].title;
    self.switchCtl.on = [self switchRow].switchValue;
}

- (OBASwitchRow*)switchRow {
    return (OBASwitchRow*)self.tableRow;
}

@end
