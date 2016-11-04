//
//  UITableViewCell+Swipe.m
//  YMSwipeTableViewCell
//
//  Created by Sumit Kumar on 4/8/15.
//  Copyright (c) 2015 Microsoft Inc. All rights reserved.
//

#import "UITableViewCell+Swipe.h"
#import <objc/runtime.h>

static const CGFloat YKTableGestureAnimationDuration = 0.3f;

static const void *YKTableGestureKey = &YKTableGestureKey;
static const void *YKTableSwipeViewKey = &YKTableSwipeViewKey;
static const void *YKTableRightViewKey = &YKTableRightViewKey;
static const void *YKTableLeftViewKey = &YKTableLeftViewKey;
static const void *YKTableSwipeModeKey = &YKTableSwipeModeKey;
static const void *YKTableSwipingEnabledKey = &YKTableSwipingEnabledKey;
static const void *YKTableCurrentSwipeModeKey = &YKTableCurrentSwipeModeKey;
static const void *YKTableSwipeContainerKey = &YKTableSwipeContainerKey;
static const void *YKTableSwipeEffectKey = &YKTableSwipeEffectKey;
static const void *YKTableSwipeStartXKey = &YKTableSwipeStartXKey;
static const void *YKTableDidSwipeBlockKey = &YKTableDidSwipeBlockKey;
static const void *YKTableDidChangeModeBlockKey = &YKTableDidChangeModeBlockKey;
static const void *YKTableWillChangeModeBlockKey = &YKTableWillChangeModeBlockKey;
static const void *YKTableSwipeAllowMultipleKey = &YKTableSwipeAllowMultipleKey;
static const void *YKTableRightSwipeSnapThresholdKey = &YKTableRightSwipeSnapThresholdKey;
static const void *YKTableLeftSwipeSnapThresholdKey = &YKTableLeftSwipeSnapThresholdKey;
static const void *YKTableSwipeContainerViewBackgroundColorKey = &YKTableSwipeContainerViewBackgroundColorKey;

@interface UITableViewCell (SwipePrivate)

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) UIView *leftView;
@property (nonatomic, strong) UIView *rightView;
@property (nonatomic, strong) UIView *swipeContainerView;
@property (nonatomic, strong) UIView *swipeView;
@property (nonatomic, readwrite) YATableSwipeMode swipeMode;
@property (nonatomic, readwrite) NSInteger startDirection;
@end

@implementation UITableViewCell (Swipe)

- (void)setPanGestureRecognizer:(UIPanGestureRecognizer *)recognizer
{
    objc_setAssociatedObject(self, YKTableGestureKey, recognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIPanGestureRecognizer*)panGestureRecognizer
{
    return objc_getAssociatedObject(self, YKTableGestureKey);
}

- (YMTableCellDidSwipeBlock)swipeBlock
{
    return objc_getAssociatedObject(self, YKTableDidSwipeBlockKey);
}

- (void)setSwipeBlock:(YMTableCellDidSwipeBlock)swipeBlock
{
    objc_setAssociatedObject(self, YKTableDidSwipeBlockKey, swipeBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (YMTableCellDidChangeModeBlock)modeChangedBlock
{
    return objc_getAssociatedObject(self, YKTableDidChangeModeBlockKey);
}

- (void)setModeChangedBlock:(YMTableCellDidChangeModeBlock)modeChangedBlock
{
    objc_setAssociatedObject(self, YKTableDidChangeModeBlockKey, modeChangedBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (YMTableCellWillChangeModeBlock)modeWillChangeBlock
{
    return objc_getAssociatedObject(self, YKTableWillChangeModeBlockKey);
}

- (void)setModeWillChangeBlock:(YMTableCellWillChangeModeBlock)modeWillChangeBlock
{
    objc_setAssociatedObject(self, YKTableWillChangeModeBlockKey, modeWillChangeBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)swipingEnabled
{
    return [objc_getAssociatedObject(self, YKTableSwipingEnabledKey) ?: @(YES) boolValue];
}

- (void)setSwipingEnabled:(BOOL)swipingEnabled
{
    objc_setAssociatedObject(self, YKTableSwipingEnabledKey, @(swipingEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)swipeView
{
    return objc_getAssociatedObject(self, YKTableSwipeViewKey);
}

- (void)setSwipeView:(UIView *)swipeView
{
    objc_setAssociatedObject(self, YKTableSwipeViewKey, swipeView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setRightView:(UIView *)rightView
{
    objc_setAssociatedObject(self, YKTableRightViewKey, rightView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView*)rightView
{
    return objc_getAssociatedObject(self, YKTableRightViewKey);
}

- (void)setLeftView:(UIView *)leftView
{
    objc_setAssociatedObject(self, YKTableLeftViewKey, leftView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView*)leftView
{
    return objc_getAssociatedObject(self, YKTableLeftViewKey);
}

- (void)setSwipeContainerView:(UIView *)swipeContainerView
{
    objc_setAssociatedObject(self, YKTableSwipeContainerKey, swipeContainerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView*)swipeContainerView
{
    return objc_getAssociatedObject(self, YKTableSwipeContainerKey);
}

- (void)setSwipeMode:(YATableSwipeMode)swipeMode
{
    objc_setAssociatedObject(self, YKTableSwipeModeKey, @(swipeMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (YATableSwipeMode)swipeMode
{
    return [objc_getAssociatedObject(self, YKTableSwipeModeKey) integerValue];
}

- (void)setCurrentSwipeMode:(YATableSwipeMode)swipeMode
{
    objc_setAssociatedObject(self, YKTableCurrentSwipeModeKey, @(swipeMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (YATableSwipeMode)currentSwipeMode
{
    return [objc_getAssociatedObject(self, YKTableCurrentSwipeModeKey) integerValue];
}

- (void)setSwipeEffect:(YATableSwipeEffect)swipeEffect
{
    objc_setAssociatedObject(self, YKTableSwipeEffectKey, @(swipeEffect), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (YATableSwipeEffect)swipeEffect
{
    return [objc_getAssociatedObject(self, YKTableSwipeEffectKey) integerValue];
}

- (void)setStartDirection:(NSInteger)startDirection
{
    objc_setAssociatedObject(self, YKTableSwipeStartXKey, @(startDirection), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)startDirection
{
    return [objc_getAssociatedObject(self, YKTableSwipeStartXKey) integerValue];
}

- (void)setAllowMultiple:(BOOL)allowMultiple
{
    objc_setAssociatedObject(self, YKTableSwipeAllowMultipleKey, @(allowMultiple), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)allowMultiple
{
    return [objc_getAssociatedObject(self, YKTableSwipeAllowMultipleKey) boolValue];
}

- (void)setRightSwipeSnapThreshold:(CGFloat)rightSwipeSnapThreshold
{
    objc_setAssociatedObject(self, YKTableRightSwipeSnapThresholdKey, @(rightSwipeSnapThreshold), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)rightSwipeSnapThreshold
{
    return [objc_getAssociatedObject(self, YKTableRightSwipeSnapThresholdKey) floatValue];
}

- (void)setLeftSwipeSnapThreshold:(CGFloat)leftSwipeSnapThreshold
{
    objc_setAssociatedObject(self, YKTableLeftSwipeSnapThresholdKey, @(leftSwipeSnapThreshold), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)leftSwipeSnapThreshold
{
    return [objc_getAssociatedObject(self, YKTableLeftSwipeSnapThresholdKey) floatValue];
}

- (void)setSwipeContainerViewBackgroundColor:(UIColor *)backgroundColor
{
    objc_setAssociatedObject(self, YKTableSwipeContainerViewBackgroundColorKey, backgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)swipeContainerViewBackgroundColor
{
    return objc_getAssociatedObject(self, YKTableSwipeContainerViewBackgroundColorKey);
}

- (void)setUpSwipe
{
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    recognizer.delegate = self;
    self.panGestureRecognizer = recognizer;
    [self addGestureRecognizer:self.panGestureRecognizer];

    self.swipeContainerView = [[UIView alloc] init];
    self.swipeContainerView.backgroundColor = (self.swipeContainerViewBackgroundColor == nil) ? [UIColor lightGrayColor] : self.swipeContainerViewBackgroundColor;
    self.swipeContainerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.swipeContainerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goToDefaultTapGesture:)]];
    [self.swipeContainerView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(goToDefaultPanGesture:)]];

    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:YMSwipeGoToDefaultMode object:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
    }
    @finally {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetToDefault:) name:YMSwipeGoToDefaultMode object:nil];
    }
}

- (void)resetSwipe:(void (^)(BOOL finished))completion withAnimation:(BOOL)animate
{
    [self goToDefaultMode:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
    } withAnimation:animate];
}

- (void)goToDefaultTapGesture:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self goToDefaultMode:nil withAnimation:YES];
    }
}

- (void)goToDefaultPanGesture:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self goToDefaultMode:nil withAnimation:YES];
    }
}

- (void)addRightView:(UIView *)view
{
    self.rightView = view;
    if (self.swipeContainerView == nil) {
        [self setUpSwipe];
    }
}

- (void)addLeftView:(UIView *)view
{
    self.leftView = view;
    if (self.swipeContainerView == nil) {
        [self setUpSwipe];
    }
}

- (void)resetToDefault:(NSNotification *)notification
{
    UITableViewCell *cell = [notification object];
    BOOL animate = [(notification.userInfo[YMSwipeGoToDefaultModeNotificationAnimationParameter]) boolValue];
    if (![cell isEqual:self]) {
        [self goToDefaultMode:nil withAnimation:animate];
    }
}

- (void)goToDefaultMode:(void (^)(BOOL finished))completion withAnimation:(BOOL)animate
{
    if (self.swipeMode != YATableSwipeModeDefault) {
        self.swipeMode = YATableSwipeModeDefault;
        [self goToCurrentSwipeMode:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
        } withAnimation:animate];
    }
}

- (void)panGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:recognizer.view];

    void (^initializeGestureRecognizerBeginningState)(void) = ^{
        self.contentView.clipsToBounds = YES;
        [self.contentView addSubview:self.swipeContainerView];
        self.swipeContainerView.layer.transform = CATransform3DIdentity;
        self.swipeContainerView.frame = self.bounds;
        [self.leftView removeFromSuperview];
        [self.rightView removeFromSuperview];
        CGFloat velocity = [recognizer velocityInView:recognizer.view].x;
        if (self.swipeEffect == YATableSwipeEffectUnmask) {
            if (velocity < 0) {
                self.rightView.frame = CGRectMake(CGRectGetWidth(self.frame) - CGRectGetWidth(self.rightView.frame), 0, CGRectGetWidth(self.rightView.frame), CGRectGetHeight(self.rightView.frame));
                [self.swipeContainerView addSubview:self.rightView];
            }
            else if (velocity > 0) {
                self.leftView.frame = CGRectMake(0, 0, CGRectGetWidth(self.leftView.frame), CGRectGetHeight(self.leftView.frame));
                [self.swipeContainerView addSubview:self.leftView];
            }
        }
        else if(self.swipeEffect == YATableSwipeEffectTrail){
            if (velocity < 0) {
                self.rightView.frame = [self startRectForCurrentEffect:CGPointMake(-1.0, 0) forView:self.rightView];
                [self.swipeContainerView addSubview:self.rightView];
            }
            else if (velocity > 0 ) {
                self.leftView.frame = [self startRectForCurrentEffect:CGPointMake(1.0, 0) forView:self.leftView];
                [self.swipeContainerView addSubview:self.leftView];
            }
        }
        UIView *snapshotView = [self.contentView snapshotViewAfterScreenUpdates:NO];
        [self setSwipeView:snapshotView];
        snapshotView.backgroundColor = self.backgroundColor;
        [self.swipeContainerView addSubview:self.swipeView];
        if (self.allowMultiple == NO) {
            NSDictionary *userInfo = @{YMSwipeGoToDefaultModeNotificationAnimationParameter : @YES};
            [[NSNotificationCenter defaultCenter] postNotificationName:YMSwipeGoToDefaultMode object:self userInfo:userInfo];
        }
    };

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        initializeGestureRecognizerBeginningState();
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        // handle the case when velocity is 0 and no right or left views are created
        if (!([self.rightView isDescendantOfView:self.swipeContainerView] || [self.leftView isDescendantOfView:self.swipeContainerView])) {
            initializeGestureRecognizerBeginningState();
        }

        // lock cell when trying to swipe to the opposite direction
        if (self.startDirection != YATableSwipeDirectionNone) {
            if (translation.x < 0 &&
                self.startDirection == YATableSwipeDirectionRight) {
                return;
            }
            if (translation.x > 0 &&
                self.startDirection == YATableSwipeDirectionLeft) {
                return;
            }
        }
        else {
            if (translation.x < 0) {
                self.startDirection = YATableSwipeDirectionLeft;
            }
            else{
                self.startDirection = YATableSwipeDirectionRight;
            }
        }

        [self.swipeView.layer setTransform:CATransform3DMakeTranslation(translation.x, 0.0, 1.0)];
        if (self.swipeEffect == YATableSwipeEffectTrail) {
            if (fabs(translation.x) < CGRectGetWidth(self.leftView.frame)) {
                self.leftView.layer.transform = self.swipeView.layer.transform;
            }
            else{
                self.leftView.layer.transform = CATransform3DMakeTranslation(CGRectGetWidth(self.leftView.frame), 0.0, 1.0);
            }
            if (fabs(translation.x) < CGRectGetWidth(self.rightView.frame)) {
                self.rightView.layer.transform = self.swipeView.layer.transform;
            }
            else{
                self.rightView.layer.transform = CATransform3DMakeTranslation(-CGRectGetWidth(self.rightView.frame), 0.0, 1.0);
            }
        }
        if (self.swipeBlock) {
            self.swipeBlock(self, translation);
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded){
        YATableSwipeMode nextMode = [self modeForVelocity:[recognizer velocityInView:recognizer.view] translation:translation];
        self.swipeMode = nextMode;
        [self goToCurrentSwipeMode:nil withAnimation:YES];
        self.startDirection = YATableSwipeDirectionNone;
    }
    else if(recognizer.state == UIGestureRecognizerStateFailed ||
            recognizer.state == UIGestureRecognizerStateCancelled){
        self.startDirection = YATableSwipeDirectionNone;
        [self goToDefaultMode:nil withAnimation:NO];
    }
}

- (CGRect)startRectForCurrentEffect:(CGPoint)translation forView:(UIView *)view
{
    return CGRectMake(translation.x >= 0 ? -CGRectGetWidth(view.bounds): (CGRectGetWidth(self.bounds)), 0, CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds));
}

- (void)goToCurrentSwipeMode:(void (^)(BOOL finished))completion withAnimation:(BOOL)animate
{
    YATableSwipeMode mode = self.swipeMode;
    if (self.modeWillChangeBlock) {
        self.modeWillChangeBlock(self, mode);
    }
    
    CATransform3D transform = [self transformForMode:mode];
    
    __weak __typeof(self) weakSelf = self;
    void(^goToCurrentSwipeModeActionBlock)() = ^{
        __typeof(self) strongSelf = weakSelf;
        [strongSelf.swipeView.layer setTransform:transform];
        if (strongSelf.swipeEffect == YATableSwipeEffectTrail) {
            strongSelf.leftView.layer.transform = strongSelf.swipeView.layer.transform;
            strongSelf.rightView.layer.transform = strongSelf.swipeView.layer.transform;
        }
    };

    void(^goToCurrentSwipeModeCompletionActionBlock)() = ^{
        __typeof(self) strongSelf = weakSelf;

        if (mode == YATableSwipeModeDefault) {
            [strongSelf.swipeContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [strongSelf.swipeContainerView removeFromSuperview];
            [strongSelf.swipeView removeFromSuperview];
            strongSelf.swipeView = nil;
        }
        if (strongSelf.modeChangedBlock) {
            strongSelf.modeChangedBlock(strongSelf, mode);
        }
    };

    if (animate) {
        [UIView animateWithDuration:YKTableGestureAnimationDuration delay:0.0 options: mode == YATableSwipeModeDefault ? UIViewAnimationOptionCurveEaseOut : UIViewAnimationOptionCurveLinear animations:^{
                goToCurrentSwipeModeActionBlock();
        } completion:^(BOOL finished) {
            if (finished) {
                goToCurrentSwipeModeCompletionActionBlock();
            }
            else{
                [self.swipeContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                [self.swipeContainerView removeFromSuperview];
                [self.swipeView removeFromSuperview];
                self.swipeView = nil;
            }
            self.currentSwipeMode = mode;
            if (completion) {
                completion(finished);
            }
        }];
    } else {
        goToCurrentSwipeModeActionBlock();
        goToCurrentSwipeModeCompletionActionBlock();
    }
}

- (CATransform3D)transformForMode:(YATableSwipeMode)mode
{
    if (mode == YATableSwipeModeLeftON) {
        return CATransform3DMakeTranslation(self.leftView.bounds.size.width, 0.0, 1.0);
    }
    else if (mode == YATableSwipeModeRightON) {
        return CATransform3DMakeTranslation(-self.rightView.bounds.size.width, 0.0, 1.0);
    }
    return CATransform3DIdentity;
}

- (YATableSwipeMode)modeForVelocity:(CGPoint)velocity translation:(CGPoint)translation
{
    if (translation.x > 0 && translation.x < self.rightSwipeSnapThreshold) {
        return YATableSwipeModeDefault;
    }
    else if (translation.x < 0 && translation.x > -self.leftSwipeSnapThreshold) {
        return YATableSwipeModeDefault;
    }
    if (velocity.x < 0) {
        if (self.swipeMode == YATableSwipeModeDefault &&
            self.startDirection == YATableSwipeDirectionLeft) {
            return YATableSwipeModeRightON;
        }
    }
    else if (velocity.x > 0) {
        if (self.swipeMode == YATableSwipeModeDefault &&
            self.startDirection == YATableSwipeDirectionRight) {
            return YATableSwipeModeLeftON;
        }
    }
    return YATableSwipeModeDefault;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (!self.swipingEnabled) {
        return NO;
    }

    if (gestureRecognizer == self.panGestureRecognizer) {
        CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:gestureRecognizer.view];
        if (translation.y == 0.f) {
            if (translation.x >= 0.f && self.leftView == nil) {
                return NO;
            }
            if (translation.x <= 0.f && self.rightView == nil) {
                return NO;
            }
            return YES;
        }
        return NO;
    } else {
        return YES;
    }
}

// when the pan gesture recognizer detects a swipe the swipeView should be set to a view; at all other times, the swipeView should be nil
- (BOOL)cellIsBeingSwiped {
    return self.swipeView != nil;
}

@end
