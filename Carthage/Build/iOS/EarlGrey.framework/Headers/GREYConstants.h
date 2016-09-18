//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <EarlGrey/GREYDefines.h>
#import <UIKit/UIKit.h>

/**
 *  Any alpha less than this value is considered hidden by Apple.
 *  @see
 *  https://developer.apple.com/library/ios/documentation/uikit/reference/uiview_class/uiview/uiview.html#//apple_ref/occ/instm/UIView/hitTest:withEvent:
 */
GREY_EXTERN const CGFloat kGREYMinimumVisibleAlpha;

/**
 *  Amount of time a "fast" swipe should last for, in seconds.
 */
GREY_EXTERN const CFTimeInterval kGREYSwipeFastDuration;

/**
 *  Amount of time a "slow" swipe should last for, in seconds.
 */
GREY_EXTERN const CFTimeInterval kGREYSwipeSlowDuration;

/**
 *  Amount of time a "fast" pinch should last for, in seconds
 */
GREY_EXTERN const CFTimeInterval kGREYPinchFastDuration;

/**
 *  Amount of time a "slow" pinch should last for, in seconds
 */
GREY_EXTERN const CFTimeInterval kGREYPinchSlowDuration;

/**
 *  Infinite timeout.
 */
GREY_EXTERN const CFTimeInterval kGREYInfiniteTimeout;

/**
 *  Limit on the number of UIPickerViews that can be pulled for getting the hierarchy.
 */
GREY_EXTERN const NSInteger kUIPickerViewMaxAccessibilityViews;

/**
 *  Amount of time a normal long press should last for, in seconds. Extracted from:
 *  @see
 *  https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UILongPressGestureRecognizer_Class/index.html#//apple_ref/occ/instp/UILongPressGestureRecognizer/minimumPressDuration
 */
GREY_EXTERN const CFTimeInterval kGREYLongPressDefaultDuration;

/**
 *  Minimum acceptable difference between two floating-point values when comparing them.
 */
GREY_EXTERN const CGFloat kGREYAcceptableFloatDifference;

/**
 *  Directions for scrolling and swiping.
 *
 *  The direction describes the motion of the view port as a result of the swipe, which is opposite
 *  to the direction the user's finger moves. For example, a scroll down the page should be
 *  expressed with @c kGREYDirectionDown as it simulates a touch that starts somewhere in the middle
 *  of the screen and moves up to simulate an absolute scroll down behavior.
 */
typedef NS_ENUM(NSInteger, GREYDirection) {
  kGREYDirectionLeft = 1,
  kGREYDirectionRight,
  kGREYDirectionUp,
  kGREYDirectionDown,
};

/**
 *  Directions for pinch gesture.
 *
 *  The direction describes the motion of the view port as a result of pinch. There are two
 *  possible directions for pinch action inward and outward.
 */
typedef NS_ENUM(NSInteger, GREYPinchDirection) {
  kGREYPinchDirectionOutward = 1,
  kGREYPinchDirectionInward,
};

/**
 *  Content edges for scrolling.
 */
typedef NS_ENUM(NSInteger, GREYContentEdge) {
  kGREYContentEdgeLeft,
  kGREYContentEdgeRight,
  kGREYContentEdgeTop,
  kGREYContentEdgeBottom,
};

/**
 *  Directions for layout specification.
 */
typedef NS_ENUM(NSInteger, GREYLayoutDirection) {
  kGREYLayoutDirectionLeft = 1,
  kGREYLayoutDirectionRight,
  kGREYLayoutDirectionUp,
  kGREYLayoutDirectionDown,
};

/**
 *  Layout attributes for matching on layouts (modelled after NSLayoutAttribute).
 */
typedef NS_ENUM(NSInteger, GREYLayoutAttribute) {
  kGREYLayoutAttributeLeft = 1,
  kGREYLayoutAttributeRight,
  kGREYLayoutAttributeTop,
  kGREYLayoutAttributeBottom,
};

/**
 *  Layout relations for comparision of layout attributes (modelled after NSLayoutRelation).
 */
typedef NS_ENUM(NSInteger, GREYLayoutRelation) {
  kGREYLayoutRelationLessThanOrEqual = -1,
  kGREYLayoutRelationEqual = 0,
  kGREYLayoutRelationGreaterThanOrEqual = 1,
};

/**
 *  Types of tap actions
 */
typedef NS_ENUM(NSInteger, GREYTapType) {
  /**
   *  Tap action for basic tap.
   */
  kGREYTapTypeShort,
  /**
   *  Tap action for long press tap.
   */
  kGREYTapTypeLong,
  /**
   *  Tap action for multiple taps (for example double tap).
   */
  kGREYTapTypeMultiple,
  /**
   *  Tap action for keyboard keys.
   */
  kGREYTapTypeKBKey,
};

/**
 *  @return A string representation of the given @c deviceOrientation.
 */
NSString *NSStringFromUIDeviceOrientation(UIDeviceOrientation deviceOrientation);

/**
 *  @return A string representation of the given @c direction.
 */
NSString *NSStringFromGREYDirection(GREYDirection direction);

/**
 *  Returns a string representation of the given @c pinchDirection.
 */
NSString *NSStringFromPinchDirection(GREYPinchDirection pinchDirection);

/**
 *  @return A string representation of the given @c edge.
 */
NSString *NSStringFromGREYContentEdge(GREYContentEdge edge);

/**
 *  @return A string representation of the given layout @c attribute.
 */
NSString *NSStringFromGREYLayoutAttribute(GREYLayoutAttribute attribute);

/**
 *  @return A string representation of the given layout @c relation.
 */
NSString *NSStringFromGREYLayoutRelation(GREYLayoutRelation relation);

/**
 *  @return A string representation of the given accessibility trait.
 */
NSString *NSStringFromUIAccessibilityTraits(UIAccessibilityTraits traits);

@interface GREYConstants : NSObject

/**
 *  @return The direction from center to the given @c edge.
 */
+ (GREYDirection)directionFromCenterForEdge:(GREYContentEdge)edge;

/**
 *  @return The edge that is in the given @c direction from the center.
 */
+ (GREYContentEdge)edgeInDirectionFromCenter:(GREYDirection)direction;

/**
 *  @return The reverse direction of the given @c direction.
 */
+ (GREYDirection)reverseOfDirection:(GREYDirection)direction;

/**
 *  @return A normalized vector in the given @c direction.
 */
+ (CGVector)normalizedVectorFromDirection:(GREYDirection)direction;

@end
