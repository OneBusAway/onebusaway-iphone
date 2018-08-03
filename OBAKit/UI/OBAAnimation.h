//
//  OBAAnimation.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

extern NSTimeInterval const OBALongAnimationDuration;

typedef void (^OBAVoidBlock)(void);
typedef void (^OBACompletionBlock)(BOOL finished);


@interface OBAAnimation : NSObject

/**
 A standard interface for performing animations.

 @param animations A block containing the operations to animate.
 */
+ (void)performAnimations:(OBAVoidBlock)animations;

/**
 A standard interface for performing animations with a completion block.

 @param animations A block containing the operations to animate.
 @param completion Called when the animations have finished.
 */
+ (void)performAnimations:(OBAVoidBlock)animations completion:(nullable OBACompletionBlock)completion;

/**
 A standard interface for performing animations with a completion block.
 Includes ability to specify if the operations should be animated or not,
 allowing for simpler calling from methods that have an `animated` parameter.

 @param animated Perform operations with animation or not.
 @param animations A block containing the operations to animate.
 */
+ (void)performAnimated:(BOOL)animated animations:(OBAVoidBlock)animations;

/**
 A standard interface for performing animations with a completion block.
 Includes ability to specify if the operations should be animated or not,
 allowing for simpler calling from methods that have an `animated` parameter.

 @param animated Perform operations with animation or not.
 @param animations A block containing the operations to animate.
 @param completion Called when the animations have finished.
 */
+ (void)performAnimated:(BOOL)animated animations:(OBAVoidBlock)animations completion:(nullable OBACompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
