//
//  OBAImageHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAImageHelpers.h>

@implementation OBAImageHelpers

+ (UIImage *)colorizeImage:(UIImage *)image withColor:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);

    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -area.size.height);

    CGContextSaveGState(context);
    CGContextClipToMask(context, area, image.CGImage);

    [color set];
    CGContextFillRect(context, area);

    CGContextRestoreGState(context);

    CGContextSetBlendMode(context, kCGBlendModeMultiply);

    CGContextDrawImage(context, area, image.CGImage);

    UIImage *colorizedImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return colorizedImage;
}

+ (UIImage*)draw:(UIImage*)image onto:(UIImage*)baseImage atPoint:(CGPoint)point {
    UIGraphicsBeginImageContextWithOptions(baseImage.size, YES, baseImage.scale);

    [baseImage drawAtPoint:CGPointZero];
    [image drawAtPoint:point];

    UIImage *compositeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return compositeImage;
}
@end
