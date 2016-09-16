//
//  OBAScopeView.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/16/12.
//
//

#import "OBAScopeView.h"
#import <QuartzCore/QuartzCore.h>
#import <OBAKit/OBAKit.h>

@interface OBAScopeView ()
- (void)_configureOBAScopeView;
@end

@implementation OBAScopeView

+ (id)layerClass {
    return [CAGradientLayer class];
}

- (void)_configureOBAScopeView {
    self.drawsBottomBorder = YES;
    self.drawsTopBorder = NO;
    self.backgroundColor = [OBATheme OBAGreenWithAlpha:0.8f];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _configureOBAScopeView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self _configureOBAScopeView];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    [[UIColor colorWithRed:(122.f / 255.f) green:(137.f / 255.f) blue:(148.f / 255.f) alpha:1.f] set];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context,1.f);
    
    if (self.drawsBottomBorder) {
        CGContextMoveToPoint(context, 0.f, CGRectGetHeight(self.frame) - 0.5f);
        CGContextAddLineToPoint(context, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame) - 0.5f);
        CGContextStrokePath(context);
    }
    
    if (self.drawsTopBorder) {
        CGContextMoveToPoint(context, 0.f, 0.5f);
        CGContextAddLineToPoint(context, CGRectGetWidth(self.frame), 0.5f);
        CGContextStrokePath(context);
    }
}

@end
