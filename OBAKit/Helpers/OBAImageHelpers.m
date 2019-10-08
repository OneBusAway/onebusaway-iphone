//
//  OBAImageHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAImageHelpers.h>

CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
};

@implementation OBAImageHelpers

+ (UIImage*)imageOfColor:(UIColor*)color size:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [color setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return img;
}

+ (CGFloat)degreesToRadians:(CGFloat)degrees {
    return DegreesToRadians(degrees);
}

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

+ (UIImage*)circleImageWithSize:(CGSize)size contents:(nullable UIImage*)image {
    return [self circleImageWithSize:size contents:image strokeColor:nil];
}

+ (UIImage*)circleImageWithSize:(CGSize)size contents:(nullable UIImage*)image strokeColor:(nullable UIColor*)strokeColor {
    BOOL opaque = NO;
    CGFloat kStrokeWidth = 2.f;
    CGRect circleRect = CGRectMake(1, 1, size.width - 2, size.height - 2);

    UIColor *circleBackground = nil;
    UIColor *circleBorder = nil;

    // Set background color
    if (@available(iOS 13, *)) {
        circleBackground = UIColor.systemBackgroundColor;
        circleBorder = UIColor.opaqueSeparatorColor;
    }
    else {
        circleBackground = UIColor.whiteColor;
        circleBorder = UIColor.lightGrayColor;
    }

    UIGraphicsBeginImageContextWithOptions(size, opaque, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(ctx, kStrokeWidth);

    [circleBackground set];
    CGContextFillEllipseInRect(ctx, circleRect);

    [(strokeColor ?: circleBorder) set];
    CGContextStrokeEllipseInRect(ctx, circleRect);

    if (image) {
        [image drawInRect:CGRectInset(circleRect, 5, 5)];
    }

    UIImage *compositeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return compositeImage;
}

// Derived from https://gist.github.com/giaesp/7704753

+ (UIImage*)rotateImage:(UIImage *)image degrees:(CGFloat)degrees {
    return [self rotateImage:image radians:DegreesToRadians(degrees)];
}

+ (UIImage*)rotateImage:(UIImage*)image radians:(CGFloat)radians {
    // Calculate Destination Size
    CGAffineTransform t = CGAffineTransformMakeRotation(radians);
    CGRect sizeRect = (CGRect) {.size = image.size};
    CGRect destRect = CGRectApplyAffineTransform(sizeRect, t);
    CGSize destinationSize = destRect.size;

    // Draw image
    UIGraphicsBeginImageContext(destinationSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, destinationSize.width / 2.0f, destinationSize.height / 2.0f);
    CGContextRotateCTM(context, radians);
    [image drawInRect:CGRectMake(-image.size.width / 2.0f, -image.size.height / 2.0f, image.size.width, image.size.height)];

    // Save image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
	// Set the image to render as template so we can adjust how it looks at runtime (i.e. change tint color).
    return [newImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}
@end
