//
//  OBACollapsingHeaderView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBACollapsingHeaderView.h"
#import <Masonry/Masonry.h>
@import OBAKit;
#import "OBARotatingButton.h"
#import "OBAAnimation.h"

@interface OBACollapsingHeaderView ()
@property(nonatomic,strong) OBARotatingButton *toggleButton;
@end

@implementation OBACollapsingHeaderView
@dynamic title;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = [OBATheme tableViewSectionHeaderBackgroundColor];

        _toggleButton = ({
            OBARotatingButton *btn = [OBARotatingButton buttonWithType:UIButtonTypeCustom];
            [btn setImage:[UIImage imageNamed:@"chevron"] forState:UIControlStateNormal];
            btn.titleLabel.font = [OBATheme boldBodyFont];
            btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            btn.titleEdgeInsets = UIEdgeInsetsMake(0, [OBATheme compactPadding], 0, 0);
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
            btn.contentEdgeInsets = self.layoutMargins;
            btn;
        });
        [self addSubview:_toggleButton];

        [_toggleButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
    }
    return self;
}

#pragma mark - Accessors

- (void)setTitle:(NSString *)title {
    [self.toggleButton setTitle:title forState:UIControlStateNormal];
}

- (NSString*)title {
    return [self.toggleButton titleForState:UIControlStateNormal];
}

- (void)setIsOpen:(BOOL)isOpen {
    _isOpen = isOpen;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
    [OBAAnimation performAnimations:^{
        self.toggleButton.imageView.transform = isOpen ? CGAffineTransformMakeRotation(M_PI_2) : CGAffineTransformIdentity;
    }];
#pragma clang diagnostic pop
}

#pragma mark - Actions

- (void)buttonTapped {
    self.isOpen = !self.isOpen;

    if (self.tapped) {
        self.tapped(self.isOpen);
    }
}
@end
