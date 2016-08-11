//
//  OBATableFooterLabelView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATableFooterLabelView.h"
#import "OBATheme.h"
#import "UILabel+OBAAdditions.h"

@interface OBATableFooterLabelView ()
@property(nonatomic,strong,readwrite) UILabel *label;
@end

@implementation OBATableFooterLabelView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        _label = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds, self.layoutMargins.left, self.layoutMargins.top)];
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _label.numberOfLines = 0;
        _label.font = [OBATheme footnoteFont];
        _label.textAlignment = NSTextAlignmentCenter;
        [_label oba_resizeHeightToFit];

        CGRect frame = self.frame;
        frame.size.height = CGRectGetMaxY(_label.frame) + self.layoutMargins.bottom;
        self.frame = frame;

        [self addSubview:_label];
    }
    return self;
}

- (void)resizeToFitText {
    [self.label oba_resizeHeightToFit];

    CGRect frame = self.frame;
    frame.size.height = CGRectGetMaxY(self.label.frame) + self.layoutMargins.bottom;
    self.frame = frame;
}
@end
