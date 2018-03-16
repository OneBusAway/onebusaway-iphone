//
//  OBAImageHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/28/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBAImageHelpers : NSObject

/**
 Creates an image of size `size` filled with color `color`.

 @param color The image fill color.
 @param size The image size.
 @return The colored, filled image.
 */
+ (UIImage*)imageOfColor:(UIColor*)color size:(CGSize)size;

/**
 Converts degrees to radians.
 TODO: create an OBAMath helper and move this in there!

 @param degrees Number of degrees
 @return Equivalent in radians
 */
+ (CGFloat)degreesToRadians:(CGFloat)degrees;

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

/**
 Creates a circle of the specified size in light gray color, optionally compositing an
 image in to the center.

 @param size Size of the circle
 @param image The image to composite into the center
 @return A circle with an optionally composited image
 */
+ (UIImage*)circleImageWithSize:(CGSize)size contents:(nullable UIImage*)image;

/**
 Creates a circle of the specified size in the specified color, optionally compositing an
 image in to the center.

 @param size Size of the circle
 @param image The image to composite into the center
 @param strokeColor The interior color of the circle. Defaults to light gray if nil.
 @return A circle with an optionally composited image
 */
+ (UIImage*)circleImageWithSize:(CGSize)size contents:(nullable UIImage*)image strokeColor:(nullable UIColor*)strokeColor;

/**
 Rotates the supplied UIImage by the specified number of degrees.

 @param image An image to rotate.
 @param degrees The number of degrees to rotate the image. Can be positive or negative.
 @return A rotated UIImage.
 */
+ (UIImage*)rotateImage:(UIImage *)image degrees:(CGFloat)degrees;
@end

NS_ASSUME_NONNULL_END
