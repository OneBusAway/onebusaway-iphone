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

#import <EarlGrey/GREYBaseAction.h>
#import <EarlGrey/GREYConstants.h>

/**
 *  Error domain used for pinch related NSError objects.
 */
GREY_EXTERN NSString *const kGREYPinchErrorDomain;

/**
 *  Error codes for pinch related failures.
 */
typedef NS_ENUM(NSInteger, GREYPinchErrorCode) {
  kGREYPinchFailedErrorCode = 0,
};

/**
 *  A @c GREYAction that pinches the view on which it is called.
 */
@interface GREYPinchAction : GREYBaseAction

/**
 *  Performs a pinch action in the given @c direction for the @c duration. The start of outward
 *  pinch is from the center of the view and stops before 20% margin of the view's
 *  width or height, on either side.
 *  For an inward pinch the start point is at a 20% margin of the view's width or height on either
 *  side and stops at the center.
 *
 *  @param direction The direction of the pinch.
 *  @param duration  The time interval for which the pinch takes place.
 *
 *  @returns An instance of @c GREYPinchAction, initialized with a provided direction and duration.
 */
- (instancetype)initWithDirection:(GREYPinchDirection)direction duration:(CFTimeInterval)duration;
@end
