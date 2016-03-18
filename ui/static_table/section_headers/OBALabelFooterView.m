//
//  OBALabelFooterView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBALabelFooterView.h"

@interface OBALabelFooterView ()
@property(nonatomic,strong) UILabel *footer;
@end

@implementation OBALabelFooterView
@dynamic text;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        self.backgroundColor = [OBATheme nonOpaquePrimaryColor];

        _footer = [[UILabel alloc] initWithFrame:self.bounds];
        _footer.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _footer.font = [OBATheme footnoteFont];
        _footer.textAlignment = NSTextAlignmentCenter;

        [self addSubview:_footer];
    }
    return self;
}

- (void)setText:(NSString *)text {
    _footer.text = text;
}

- (NSString*)text {
    return _footer.text;
}
@end
