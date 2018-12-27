//
//  UIImage+OBAAdditions.m
//  OBAKit
//
//  Created by Aaron Brethorst on 12/27/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/UIImage+OBAAdditions.h>

@implementation UIImage (OBAAdditions)

- (UIImage *)oba_imageScaledToSize:(CGSize)size {
    //create drawing context
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);

    //draw
    [self drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];

    //capture resultant image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)oba_imageScaledToFitSize:(CGSize)size {
    //calculate rect
    CGFloat aspect = self.size.width / self.size.height;
    if (size.width / aspect <= size.height) {
        return [self oba_imageScaledToSize:CGSizeMake(size.width, size.width / aspect)];
    }
    else {
        return [self oba_imageScaledToSize:CGSizeMake(size.height * aspect, size.height)];
    }
}

@end
