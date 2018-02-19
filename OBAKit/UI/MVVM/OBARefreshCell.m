//
//  OBARefreshCell.m
//  OBAKit
//
//  Created by Aaron Brethorst on 2/14/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBARefreshCell.h>
#import <OBAKit/OBARefreshRow.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/OBAStrings.h>
#import <OBAKit/NSDate+DateTools.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBATheme.h>
@import Masonry;

@interface OBARefreshCell ()
@property(nonatomic,copy,readonly) OBARefreshRow *refreshRow;

@property(nonatomic,strong) UILabel *lastUpdatedLabel;
@property(nonatomic,strong) UIImageView *refreshImageView;
@property(nonatomic,strong) UIActivityIndicatorView *activityView;
@property(nonatomic,strong) UILabel *refreshLabel;

@property(nonatomic,strong) NSDateFormatter *todayFormatter;
@property(nonatomic,strong) NSDateFormatter *anyDayFormatter;
@end

@implementation OBARefreshCell
@synthesize tableRow = _tableRow;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (self) {
        _lastUpdatedLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _lastUpdatedLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _lastUpdatedLabel.font = OBATheme.footnoteFont;

        UIImage *img = [UIImage imageNamed:@"refresh" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil];
        _refreshImageView = [[UIImageView alloc] initWithImage:img];
        _refreshImageView.contentMode = UIViewContentModeScaleAspectFit;

        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityView.hidesWhenStopped = YES;

        _refreshLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _refreshLabel.text = OBAStrings.refresh;
        _refreshLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _refreshLabel.font = OBATheme.footnoteFont;

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[_lastUpdatedLabel, UIView.new, _activityView, _refreshImageView, _refreshLabel]];
        stack.axis = UILayoutConstraintAxisHorizontal;
        stack.spacing = OBATheme.compactPadding;

        [self.contentView addSubview:stack];
        [stack mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(OBATheme.defaultEdgeInsets);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];

    self.refreshImageView.hidden = YES;
    [self.activityView stopAnimating];
    self.lastUpdatedLabel.text = nil;
    self.refreshLabel.text = nil;
}

- (void)setTableRow:(OBARefreshRow*)tableRow {
    OBAGuardClass(tableRow, OBARefreshRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    self.lastUpdatedLabel.text = [self formattedLastUpdatedAt];

    if (self.refreshRow.rowState == OBARefreshRowStateNormal) {
        self.refreshLabel.text = OBAStrings.refresh;
        self.refreshImageView.hidden = NO;
    }
    else {
        self.refreshImageView.hidden = YES;
        self.refreshLabel.text = OBAStrings.updating;
        [self.activityView startAnimating];
    }
}

#pragma mark - Properties

- (OBARefreshRow*)refreshRow {
    return (OBARefreshRow*)self.tableRow;
}

- (NSString*)formattedLastUpdatedAt {
    NSDate *date = self.refreshRow.date;
    NSString *formatString = OBALocalized(@"refresh_cell.last_updated_format", @"Last updated: {TIME}");

    if (!date) {
        return [NSString stringWithFormat:formatString, OBAStrings.never];
    }
    else if (date.isToday) {
        return [NSString stringWithFormat:formatString, [self.todayFormatter stringFromDate:date]];
    }
    else {
        return [NSString stringWithFormat:formatString, [self.anyDayFormatter stringFromDate:date]];
    }
}

- (NSDateFormatter*)todayFormatter {
    if (!_todayFormatter) {
        _todayFormatter = [[NSDateFormatter alloc] init];
        _todayFormatter.dateStyle = NSDateFormatterNoStyle;
        _todayFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return _todayFormatter;
}

- (NSDateFormatter*)anyDayFormatter {
    if (!_anyDayFormatter) {
        _anyDayFormatter = [[NSDateFormatter alloc] init];
        _anyDayFormatter.dateStyle = NSDateFormatterShortStyle;
        _anyDayFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return _anyDayFormatter;
}

@end
