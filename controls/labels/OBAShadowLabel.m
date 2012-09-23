//
//  OBAShadowLabel.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/23/12.
//
//

#import "OBAShadowLabel.h"

@implementation OBAShadowLabel

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.clipsToBounds = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.clipsToBounds = NO;
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat colorValues[] = {0.f, 0.f, 0.f, 0.4f};
    CGColorRef shadowColor = CGColorCreate(rgbColorSpace, colorValues);
    CGSize shadowOffset = CGSizeMake(0, 0);
    CGContextSetShadowWithColor(context, shadowOffset, 4 /* blur */, shadowColor);
    [super drawTextInRect:rect];
    CGColorRelease(shadowColor);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRestoreGState(context);
}

@end
