//
//  OBALabelActivityIndicatorView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/20/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBALabelActivityIndicatorView.h"
#import <Masonry/Masonry.h>
#import <OBAKit/OBAKit.h>

@interface OBALabelActivityIndicatorView ()
@property(nonatomic,strong,readwrite) UILabel *textLabel;
@property(nonatomic,strong,readwrite) UIActivityIndicatorView *activity;
@end

@implementation OBALabelActivityIndicatorView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.clipsToBounds = YES;
        _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _textLabel.numberOfLines = 0;
        _textLabel.text = NSLocalizedString(@"Loading", @"");

        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

        [self addSubview:_textLabel];
        [self addSubview:_activity];

        [_textLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.top.and.bottom.equalTo(self);
            make.width.lessThanOrEqualTo(self);
        }];

        [_activity mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.textLabel.mas_left).offset(-[OBATheme compactPadding]);
            make.centerY.equalTo(self);
        }];
    }

    return self;
}

#pragma mark - Public Methods

- (void)startAnimating {
    [self.activity startAnimating];
}

- (void)stopAnimating {
    [self.activity stopAnimating];
}

- (void)prepareForReuse {
    self.textLabel.text = NSLocalizedString(@"Loading", @"");
    [self.activity stopAnimating];
}

@end
