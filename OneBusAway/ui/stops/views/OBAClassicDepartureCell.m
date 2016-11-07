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
#import "UITableViewCell+Swipe.h"
#import "YMTwoButtonSwipeView.h"

static CGFloat const kSwipeViewWidth = 150.f;

@interface OBAClassicDepartureCell ()
@property(nonatomic,strong) OBAClassicDepartureView *departureView;
@property(nonatomic,strong) YMTwoButtonSwipeView *rightSwipeView;
@property(nonatomic,strong,readonly) UIButton *bookmarkButton;
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

        _rightSwipeView = [[YMTwoButtonSwipeView alloc] initWithFrame:CGRectMake(0, 0, kSwipeViewWidth, CGRectGetHeight(self.frame))];

        [self configureBookmarkButtonForExistingBookmark:NO];
        [self configureBookmarkButton];
        [self configureShareButton];
        [self addRightView:_rightSwipeView];
    }

    return self;
}

#pragma mark - Buttons

- (UIButton*)bookmarkButton {
    return self.rightSwipeView.leftButton;
}

- (UIButton*)shareButton {
    return self.rightSwipeView.rightButton;
}

- (void)configureBookmarkButton {
    [self.bookmarkButton addTarget:self action:@selector(toggleBookmark) forControlEvents:UIControlEventTouchUpInside];
    self.bookmarkButton.titleLabel.font = [OBATheme footnoteFont];
    [self.bookmarkButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

- (void)configureBookmarkButtonForExistingBookmark:(BOOL)bookmarkExists {

    UIColor *backgroundColor = nil;
    UIImage *image = nil;
    NSString *title = nil;
    NSString *accessibilityLabel = nil;

    if (bookmarkExists) {
        backgroundColor = [UIColor redColor];
        image = [UIImage imageNamed:@"Favorites_Selected"];
        title = NSLocalizedString(@"Remove",);
        accessibilityLabel = NSLocalizedString(@"Remove Bookmark",);
    }
    else {
        backgroundColor = [UIColor greenColor];
        image = [UIImage imageNamed:@"Favorites"];
        title = NSLocalizedString(@"Add",);
        accessibilityLabel = NSLocalizedString(@"Add Bookmark",);
    }

    [self.bookmarkButton setBackgroundColor:backgroundColor];
    [self.bookmarkButton setImage:image forState:UIControlStateNormal];
    [self.bookmarkButton setTitle:title forState:UIControlStateNormal];
    [self.bookmarkButton setAccessibilityLabel:accessibilityLabel];
}

- (void)configureShareButton {
    [self.shareButton setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
    [self.shareButton setTitle:NSLocalizedString(@"Share",) forState:UIControlStateNormal];
    [self.shareButton setBackgroundColor:[UIColor lightGrayColor]];
    [self.shareButton addTarget:self action:@selector(shareDeparture) forControlEvents:UIControlEventTouchUpInside];
    [self.shareButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.shareButton.titleLabel.font = [OBATheme footnoteFont];
}

- (void)toggleBookmark {
    if ([self departureRow].toggleBookmarkAction) {
        [self departureRow].toggleBookmarkAction();
    }
    [self resetSwipe:nil withAnimation:YES];
}

- (void)shareDeparture {
    if ([self departureRow].shareAction) {
        [self departureRow].shareAction();
    }
    [self resetSwipe:nil withAnimation:YES];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    _rightSwipeView.frame = CGRectMake(0, 0, kSwipeViewWidth, CGRectGetHeight(self.frame));
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];

    [self resetSwipe:nil withAnimation:NO];

    [self.departureView prepareForReuse];
}

#pragma mark - OBATableCell

- (void)setTableRow:(OBABaseRow *)tableRow {

    OBAGuardClass(tableRow, OBADepartureRow) else {
        return;
    }

    _tableRow = [tableRow copy];

    [self configureBookmarkButtonForExistingBookmark:[self departureRow].bookmarkExists];

    self.accessoryType = [self departureRow].accessoryType;

    self.departureView.departureRow = [self departureRow];
}

- (OBADepartureRow*)departureRow {
    return (OBADepartureRow*)[self tableRow];
}

@end
