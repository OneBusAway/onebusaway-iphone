//
//  OBAStopSectionHeaderView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAStopSectionHeaderView.h"
#import "OBATheme.h"

#define SHOW_PER_SECTION_BOOKMARK_BUTTON 0

@interface OBAStopSectionHeaderView ()
@property(nonatomic,strong) UILabel *routeNameLabel;
@property(nonatomic,strong) UIButton *favoriteButton;
@end

@implementation OBAStopSectionHeaderView
@dynamic routeNameText;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = [OBATheme nonOpaquePrimaryColor];

        _routeNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];

#if SHOW_PER_SECTION_BOOKMARK_BUTTON
        _favoriteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _favoriteButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_favoriteButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_favoriteButton setImage:[UIImage imageNamed:@"star_unfilled"] forState:UIControlStateNormal];
        [_favoriteButton setImage:[UIImage imageNamed:@"star_filled"] forState:UIControlStateSelected];
        _favoriteButton.accessibilityLabel = NSLocalizedString(@"Mark this route and stop as a favorite.", @"");

        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_routeNameLabel, _favoriteButton]];
        stackView.layoutMarginsRelativeArrangement = YES;
        stackView.layoutMargins = self.layoutMargins;
        stackView.frame = self.bounds;
        stackView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self addSubview:stackView];
#else
        _routeNameLabel.frame = self.bounds;
        _routeNameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self addSubview:_routeNameLabel];
#endif
    }
    return self;
}

#pragma mark - Actions

- (void)buttonTapped:(UIButton*)button {
    button.selected = !button.selected;
    if (self.favoriteButtonTapped) {
        self.favoriteButtonTapped(button.selected);
    }
}

#pragma mark - Accessors

- (void)setRouteNameText:(NSString *)routeNameText {

    NSDictionary *attrs = @{ NSForegroundColorAttributeName: [UIColor blackColor],
                             NSFontAttributeName: [OBATheme titleFont] };

    NSAttributedString* attrString = [[NSAttributedString alloc]
                                      initWithString:routeNameText
                                      attributes:attrs];

    self.routeNameLabel.attributedText = attrString;
}

- (NSString*)routeNameText {
    return self.routeNameLabel.text;
}

@end
