//
//  OBAImageHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;

@interface OBAImageHelpers : NSObject

/**
 Overlays the image parameter with the specified color using the multiply blend mode.

 @param image The image object that will have a color overlay applied to it.
 @param color The color that will be overlayed on top of the image.

 @return A new image object with the specified color applied on top of it.
 */
+ (UIImage*)colorizeImage:(UIImage *)image withColor:(UIColor *)color;

/**
 Draws one image on top of another at the specified location.

 @param image     The image that is drawn on top of the baseImage.
 @param baseImage The image upon which new content is drawn.
 @param point     The point in the base image that the image is drawn at.

 @return The new composite image.
 */
+ (UIImage*)draw:(UIImage*)image onto:(UIImage*)baseImage atPoint:(CGPoint)point;

@end
