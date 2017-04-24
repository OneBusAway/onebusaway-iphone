//
//  OBAClassicDepartureCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAClassicDepartureCell.h"
@import Masonry;
#import "OBADepartureRow.h"
#import "OBAClassicDepartureView.h"
#import "OBAStackedButton.h"

@interface OBAClassicDepartureCell ()
@property(nonatomic,strong) OBAClassicDepartureView *departureView;
@property(nonatomic,strong) UIButton *contextMenuButton;
@end

@implementation OBAClassicDepartureCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.contentView.clipsToBounds = YES;

        _contextMenuButton = [self buildContextMenuButton];
        _departureView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
        UIView *wrapperView = [[UIView alloc] initWithFrame:CGRectZero];
        wrapperView.clipsToBounds = YES;

        [wrapperView addSubview:_departureView];
        [wrapperView addSubview:_contextMenuButton];

        [self.contentView addSubview:wrapperView];

        [wrapperView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(self.layoutMargins);
        }];

        [_contextMenuButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.and.width.equalTo(@40);
            make.right.equalTo(wrapperView);
            make.centerY.equalTo(wrapperView);
        }];

        [_departureView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.and.bottom.equalTo(wrapperView);
            make.right.equalTo(self->_contextMenuButton.mas_left);
        }];
    }

    return self;
}

#pragma mark - Context Menu

- (UIButton*)buildContextMenuButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *ellipsis = [UIImage imageNamed:@"ellipsis_button"];
    [button setImage:ellipsis forState:UIControlStateNormal];
    button.tintColor = [OBATheme OBAGreenWithAlpha:0.7f];
    button.accessibilityLabel = NSLocalizedString(@"classic_departure_cell.context_button_accessibility_label", @"This is the ... button shown on the right side of a departure cell. Tapping it shows a menu with more options.");
    [button addTarget:self action:@selector(showActionMenu) forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (void)showActionMenu {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"classic_departure_cell.context_alert.title", @"Title for the context menu button's alert controller.") message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];

    // Add Bookmark
    UIAlertAction *action = [UIAlertAction actionWithTitle:[self bookmarkButtonTitle] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self toggleBookmark];
    }];
    [action setValue:[UIImage imageNamed:@"Favorites_Selected"] forKey:@"image"];
    [alert addAction:action];

    // Set Alarm
    action = [UIAlertAction actionWithTitle:[self alarmButtonTitle] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self toggleAlarm];
    }];
    [action setValue:[UIImage imageNamed:@"bell"] forKey:@"image"];
    [alert addAction:action];

    action = [UIAlertAction actionWithTitle:NSLocalizedString(@"classic_departure_cell.context_alert.share_trip_status", @"Title for alert controller's Share Trip Status option.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self shareDeparture];
    }];
    [action setValue:[UIImage imageNamed:@"share"] forKey:@"image"];
    [alert addAction:action];

    if ([self departureRow].showAlertController) {
        [self departureRow].showAlertController(alert);
    }
}

- (NSString*)bookmarkButtonTitle {
    if ([self departureRow].bookmarkExists) {
        return NSLocalizedString(@"msg_remove_bookmark", @"Title for the alert controller option that removes an existing bookmark");
    }
    else {
        return NSLocalizedString(@"msg_add_bookmark",);
    }
}

- (NSString*)alarmButtonTitle {
    if ([self departureRow].alarmExists) {
        return NSLocalizedString(@"classic_departure_cell.context_alert.remove_alarm", @"Title for alert controller's Remove Alarm option.");
    }
    else {
        return NSLocalizedString(@"classic_departure_cell.context_alert.set_alarm", @"Title for alert controller's Set Alarm option.");
    }
}

- (void)toggleBookmark {
    if ([self departureRow].toggleBookmarkAction) {
        [self departureRow].toggleBookmarkAction();
    }
}

- (void)toggleAlarm {
    if ([self departureRow].toggleAlarmAction) {
        [self departureRow].toggleAlarmAction();
    }
}

- (void)shareDeparture {
    if ([self departureRow].shareAction) {
        [self departureRow].shareAction();
    }
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];

    [self.departureView prepareForReuse];
}

#pragma mark - OBATableCell

- (void)setTableRow:(OBABaseRow *)tableRow {
    OBAGuardClass(tableRow, OBADepartureRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.accessoryType = [self departureRow].accessoryType;

    self.departureView.departureRow = [self departureRow];
}

- (OBADepartureRow*)departureRow {
    return (OBADepartureRow*)[self tableRow];
}

@end
