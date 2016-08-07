//
//  OBAMapActivityIndicatorView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAMapActivityIndicatorView.h"

@interface OBAMapActivityIndicatorView ()
@property(nonatomic,strong) UIActivityIndicatorView *activityIndicatorView;
@end

@implementation OBAMapActivityIndicatorView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {

        self.backgroundColor = OBARGBACOLOR(0, 0, 0, 0.5);
        self.layer.cornerRadius = 4.f;
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;

        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectInset(self.bounds, 4, 4)];
        _activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        [self addSubview:_activityIndicatorView];
    }
    return self;
}

- (void)startAnimating {
    [self.activityIndicatorView startAnimating];
}

- (void)stopAnimating {
    [self.activityIndicatorView stopAnimating];
}

@end
