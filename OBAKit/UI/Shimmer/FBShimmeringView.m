/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OBAKit/FBShimmeringView.h>
#import <OBAKit/FBShimmeringLayer.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Convert your project to ARC or specify the -fobjc-arc flag.
#endif

@implementation FBShimmeringView

+ (Class)layerClass
{
  return [FBShimmeringLayer class];
}

#define __layer ((FBShimmeringLayer *)self.layer)

#define LAYER_ACCESSOR(accessor, ctype) \
- (ctype)accessor { \
  return [__layer accessor]; \
}

#define LAYER_MUTATOR(mutator, ctype) \
- (void)mutator (ctype)value { \
  [__layer mutator value]; \
}

#define LAYER_RW_PROPERTY(accessor, mutator, ctype) \
  LAYER_ACCESSOR (accessor, ctype) \
  LAYER_MUTATOR (mutator, ctype)

LAYER_RW_PROPERTY(isShimmering, setShimmering:, BOOL)
LAYER_RW_PROPERTY(shimmeringPauseDuration, setShimmeringPauseDuration:, CFTimeInterval)
LAYER_RW_PROPERTY(shimmeringAnimationOpacity, setShimmeringAnimationOpacity:, CGFloat)
LAYER_RW_PROPERTY(shimmeringOpacity, setShimmeringOpacity:, CGFloat)
LAYER_RW_PROPERTY(shimmeringSpeed, setShimmeringSpeed:, CGFloat)
LAYER_RW_PROPERTY(shimmeringHighlightLength, setShimmeringHighlightLength:, CGFloat)
LAYER_RW_PROPERTY(shimmeringDirection, setShimmeringDirection:, FBShimmerDirection)
LAYER_ACCESSOR(shimmeringFadeTime, CFTimeInterval)
LAYER_RW_PROPERTY(shimmeringBeginFadeDuration, setShimmeringBeginFadeDuration:, CFTimeInterval)
LAYER_RW_PROPERTY(shimmeringEndFadeDuration, setShimmeringEndFadeDuration:, CFTimeInterval)
LAYER_RW_PROPERTY(shimmeringBeginTime, setShimmeringBeginTime:, CFTimeInterval)

- (void)setContentView:(UIView *)contentView
{
  if (contentView != _contentView) {
    _contentView = contentView;
    [self addSubview:contentView];
    __layer.contentLayer = contentView.layer;
  }
}

- (void)layoutSubviews
{
  // Autolayout requires these to be set on the UIView, not the CALayer.
  // Do this *before* the layer has a chance to set the properties, as the
  // setters would be ignored (even for autolayout) if set to the same value.
  _contentView.bounds = self.bounds;
  _contentView.center = self.center;

  [super layoutSubviews];
}

@end
