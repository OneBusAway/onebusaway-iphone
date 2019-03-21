//
//  OBAValue1ContentsView.m
//  OBAKit
//
//  Created by Aaron Brethorst on 12/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAValue1ContentsView.h>
#import <OBAKit/OBATheme.h>
@import Masonry;

@interface OBAValue1ContentsView ()
@property(nonatomic,strong) UIStackView *stackView;
@property(nonatomic,strong,readwrite) UILabel *textLabel;
@property(nonatomic,strong,readwrite) UILabel *detailTextLabel;
@end

@implementation OBAValue1ContentsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;

        _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _textLabel.numberOfLines = 0;

        _detailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailTextLabel.numberOfLines = 1;
        _detailTextLabel.textColor = [UIColor darkGrayColor];
        _detailTextLabel.textAlignment = NSTextAlignmentRight;

        // Lower hugging priority means grow bigger.
        // Higher hugging priority means stay the same and resist getting bigger.

        // Lower compression resistance means compress and make smaller.
        // Higher compression resistance means stay the same and resist getting smaller.

        [_imageView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_imageView setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

        [_textLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_textLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        [_detailTextLabel setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        [_detailTextLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_textLabel, _detailTextLabel]];
        _stackView.axis = UILayoutConstraintAxisHorizontal;
        _stackView.alignment = UIStackViewAlignmentCenter;
        _stackView.spacing = [OBATheme defaultPadding];

        [self addSubview:_imageView];
        [self addSubview:_stackView];

        [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.centerY.equalTo(self);
            make.width.and.height.lessThanOrEqualTo(@30);
        }];

        [_stackView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_imageView.mas_right).offset([OBATheme defaultPadding]);
            make.top.right.and.bottom.equalTo(self);
        }];

    }
    return self;
}

#pragma mark - Public

- (void)prepareForReuse {
    self.imageView.image = nil;
    self.imageView.hidden = YES;
    self.textLabel.text = nil;
    self.textLabel.font = nil;
    self.detailTextLabel.font = nil;
}

@end
