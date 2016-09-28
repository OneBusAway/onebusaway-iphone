//
//  OBAAnimation.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/7/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSTimeInterval const OBALongAnimationDuration;

@interface OBAAnimation : NSObject

/**
 A standard interface for performing animations.

 @param animations A block containing the operations to animate.
 */
+ (void)performAnimations:(void (^)(void))animations;

/**
 A standard interface for performing animations with a completion block.

 @param animations A block containing the operations to animate.
 @param completion Called when the animations have finished.
 */
+ (void)performAnimations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;

@end
