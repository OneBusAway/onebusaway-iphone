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

static CGFloat const kSwipeButtonWidth = 80.f;

@interface OBAClassicDepartureCell ()
@property(nonatomic,strong) OBAClassicDepartureView *departureView;
@property(nonatomic,strong,readonly) UIButton *bookmarkButton;
@property(nonatomic,strong,readonly) UIButton *alarmButton;
@property(nonatomic,strong,readonly) UIButton *shareButton;
@end

@implementation OBAClassicDepartureCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        _departureView = [[OBAClassicDepartureView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_departureView];

        [_departureView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(self.layoutMargins);
        }];

        _bookmarkButton = ({
            UIButton *button = [OBAStackedButton buttonWithType:UIButtonTypeSystem];
            [button addTarget:self action:@selector(toggleBookmark) forControlEvents:UIControlEventTouchUpInside];
            button.titleLabel.font = [OBATheme footnoteFont];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"Favorites"] forState:UIControlStateNormal];
            button.tintColor = [UIColor blackColor];

            button;
        });

        _alarmButton = ({
            UIButton *button = [OBAStackedButton buttonWithType:UIButtonTypeSystem];
            [button addTarget:self action:@selector(toggleAlarm) forControlEvents:UIControlEventTouchUpInside];
            button.titleLabel.font = [OBATheme footnoteFont];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"bell"] forState:UIControlStateNormal];
            button.tintColor = [UIColor blackColor];
            [button setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
            button;
        });

        _shareButton = ({
            UIButton *button = [OBAStackedButton buttonWithType:UIButtonTypeSystem];
            [button setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
            [button setTitle:NSLocalizedString(@"msg_share",) forState:UIControlStateNormal];
            button.backgroundColor = [UIColor lightGrayColor];
            [button addTarget:self action:@selector(shareDeparture) forControlEvents:UIControlEventTouchUpInside];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [OBATheme footnoteFont];
            button.tintColor = [UIColor blackColor];

            button;
        });

        [self addButtonsToContextMenu];
    }

    return self;
}

#pragma mark - Buttons

- (void)addButtonsToContextMenu {
    [self addLeftButton:_bookmarkButton withWidth:kSwipeButtonWidth withTappedBlock:nil];
    [self addCenterButton:_alarmButton withWidth:kSwipeButtonWidth withTappedBlock:nil];
    [self addRightButton:_shareButton withWidth:kSwipeButtonWidth withTappedBlock:nil];
}

- (void)configureBookmarkButtonForExistingBookmark:(BOOL)bookmarkExists {
    UIColor *backgroundColor = nil;
    NSString *title = nil;
    NSString *accessibilityLabel = nil;

    if (bookmarkExists) {
        backgroundColor = [UIColor redColor];

        title = NSLocalizedString(@"msg_remove",);
        accessibilityLabel = NSLocalizedString(@"msg_remove_bookmark",);
    }
    else {
        backgroundColor = [UIColor greenColor];
        title = NSLocalizedString(@"stops_controller.cell.add_bookmark_title", @"Title of the swipe to reveal button on Stop cells for adding a bookmark.");
        accessibilityLabel = NSLocalizedString(@"msg_add_bookmark",);
    }

    [self.bookmarkButton setBackgroundColor:backgroundColor];
    [self.bookmarkButton setTitle:title forState:UIControlStateNormal];
    [self.bookmarkButton setAccessibilityLabel:accessibilityLabel];
}

- (void)configureAlarmButton {
    UIColor *backgroundColor = nil;
    NSString *title = nil;
    NSString *accessibilityLabel = nil;
    BOOL enabled = YES;

    if ([self departureRow].alarmExists) {
        backgroundColor = [UIColor redColor];

        title = NSLocalizedString(@"msg_remove",);
        accessibilityLabel = NSLocalizedString(@"msg_remove_alarm",);
    }
    else {
        backgroundColor = [OBATheme OBAGreen];
        title = NSLocalizedString(@"stops_controller.cell.add_alarm_title", @"Title of the swipe to reveal button on Stop cells that triggers an alarm.");
        accessibilityLabel = NSLocalizedString(@"msg_add_alarm",);
        enabled = [self departureRow].alarmCanBeCreated;
    }

    self.alarmButton.enabled = enabled;
    self.alarmButton.backgroundColor = backgroundColor;
    [self.alarmButton setTitle:title forState:UIControlStateNormal];
    [self.alarmButton setAccessibilityLabel:accessibilityLabel];
}

- (void)toggleBookmark {
    if ([self departureRow].toggleBookmarkAction) {
        [self departureRow].toggleBookmarkAction();
    }
    [self hideButtonViewAnimated:YES];
}

- (void)toggleAlarm {
    if ([self departureRow].toggleAlarmAction) {
        [self departureRow].toggleAlarmAction();
    }
    [self hideButtonViewAnimated:YES];
}

- (void)shareDeparture {
    if ([self departureRow].shareAction) {
        [self departureRow].shareAction();
    }
    [self hideButtonViewAnimated:YES];
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];

    [self addButtonsToContextMenu];

    [self.departureView prepareForReuse];
}

#pragma mark - OBATableCell

- (void)setTableRow:(OBABaseRow *)tableRow {

    OBAGuardClass(tableRow, OBADepartureRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    [self configureBookmarkButtonForExistingBookmark:[self departureRow].bookmarkExists];
    [self configureAlarmButton];

    self.accessoryType = [self departureRow].accessoryType;

    self.departureView.departureRow = [self departureRow];
}

- (OBADepartureRow*)departureRow {
    return (OBADepartureRow*)[self tableRow];
}

@end
