//
//  OBAMessageCell.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/22/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBAMessageCell.h"
@import Masonry;
#import "OBAMessageRow.h"

static CGFloat const kAccessoryWidth = 12.f;

@interface OBAMessageCell ()
@property(nonatomic,strong) UILabel *senderLabel;
@property(nonatomic,strong) UILabel *subjectLabel;
@property(nonatomic,strong) UILabel *dateLabel;
@property(nonatomic,strong) UIImageView *unreadImageView;
@property(nonatomic,strong) UILabel *priorityLabel;
@end

@implementation OBAMessageCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        UIColor *subduedColor = [UIColor darkGrayColor];
        CGFloat compact = [OBATheme compactPadding];
        CGFloat regular = [OBATheme defaultPadding];

        // Top Row: [unread] - [sender] - [date] - [arrow]

        _unreadImageView = [[UIImageView alloc] initWithImage:nil];
        _unreadImageView.contentMode = UIViewContentModeScaleAspectFit;
        [_unreadImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(kAccessoryWidth));
        }];

        _senderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _senderLabel.font = [OBATheme boldBodyFont];

        _dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _dateLabel.textAlignment = NSTextAlignmentRight;
        _dateLabel.font = [OBATheme footnoteFont];
        _dateLabel.textColor = subduedColor;

        UIImage *disclosureArrow = [UIImage imageNamed:@"disclosure_arrow"];
        UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:disclosureArrow];
        arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
        arrowImageView.tintColor = [UIColor grayColor];
        [arrowImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@7);
        }];

        UIStackView *topRowStack = [[UIStackView alloc] initWithArrangedSubviews:@[_unreadImageView, _senderLabel, _dateLabel, arrowImageView]];
        topRowStack.axis = UILayoutConstraintAxisHorizontal;
        topRowStack.spacing = [OBATheme compactPadding];

        // Middle Row: [high pri] - [subject]

        _priorityLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _priorityLabel.textAlignment = NSTextAlignmentCenter;
        _priorityLabel.font = [OBATheme boldBodyFont];
        _priorityLabel.textColor = [UIColor redColor];
        [_priorityLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(kAccessoryWidth));
        }];

        _subjectLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _subjectLabel.font = [OBATheme bodyFont];
        _subjectLabel.textColor = subduedColor;
        _subjectLabel.numberOfLines = 3;

        UIStackView *middleRowStack = [[UIStackView alloc] initWithArrangedSubviews:@[_priorityLabel, _subjectLabel]];
        middleRowStack.axis = UILayoutConstraintAxisHorizontal;
        middleRowStack.spacing = [OBATheme compactPadding];

        UIStackView *uberStack = [[UIStackView alloc] initWithArrangedSubviews:@[topRowStack, middleRowStack]];
        uberStack.spacing = compact;
        uberStack.axis = UILayoutConstraintAxisVertical;
        [self.contentView addSubview:uberStack];
        [uberStack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(compact, regular, compact, regular));
            make.height.greaterThanOrEqualTo(@44);
        }];
    }

    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.unreadImageView.image = nil;
    self.unreadImageView.accessibilityLabel = nil;

    self.priorityLabel.text = nil;
    self.priorityLabel.accessibilityLabel = nil;
}

- (void)setTableRow:(OBABaseRow *)tableRow {
    OBAGuardClass(tableRow, OBAMessageRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.senderLabel.text = [self messageRow].sender;
    self.subjectLabel.text = [self messageRow].subject;

    [self configureDateLabelForDate:self.messageRow.date];

    self.unreadImageView.alpha = [self messageRow].unread ? 1.f : 0.f;

    if ([self messageRow].unread) {
        self.unreadImageView.image = [UIImage imageNamed:@"unread"];
        self.unreadImageView.accessibilityLabel = NSLocalizedString(@"message_cell.unread_message", @"Accessibility label with the text 'unread', as in 'an unread message'");
    }

    if ([self messageRow].highPriority) {
        self.priorityLabel.text = @"!";
        self.priorityLabel.accessibilityLabel = NSLocalizedString(@"message_cell.high_priority", @"accessibility label with the text 'high priority'.");
    }
}

- (void)configureDateLabelForDate:(nullable NSDate*)date {
    if (![self messageRow].date) {
        self.dateLabel.text = nil;
        return;
    }

    if ([self messageRow].date.isToday) {
        self.dateLabel.text = [OBADateHelpers formatShortTimeNoDate:[self messageRow].date];
    }
    else if ([self messageRow].date.isYesterday) {
        self.dateLabel.text = OBAStrings.yesterday;
    }
    else {
        self.dateLabel.text = [OBADateHelpers formatNoTimeShortDate:self.messageRow.date];
    }
}

- (OBAMessageRow*)messageRow {
    return (OBAMessageRow*)self.tableRow;
}

@end
