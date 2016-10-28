//
//  UITableViewCell+Swipe.h
//  YMSwipeTableViewCell
//
//  Created by Sumit Kumar on 4/8/15.
//  Copyright (c) 2015 Microsoft Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
static NSString * const YMSwipeGoToDefaultMode = @"YMSwipeGoToDefaultMode";
static NSString * const YMSwipeGoToDefaultModeNotificationAnimationParameter = @"animate";

/** Swipe state of the cell. */
typedef NS_ENUM(NSInteger, YATableSwipeMode) {
    /** The default cell state. The user has not begun swiping the cell. */
    YATableSwipeModeDefault,
    /** The left swipe view is completely exposed. The user has completed swiping from right to left. */
    YATableSwipeModeLeftON,
    /** The right swipe view is completely exposed. The user has completed swiping from left to right. */
    YATableSwipeModeRightON
};

/** Type of swipe effect */
typedef NS_ENUM(NSInteger, YATableSwipeEffect) {
    /** Swipe image is underneath the cell and is fixed during a swipe. */
    YATableSwipeEffectUnmask,
    /** The swipe image is clamped to the cell and is moving with the cell during a swipe. */
    YATableSwipeEffectTrail
};

/** Swipe direction */
typedef NS_ENUM(NSInteger, YATableSwipeDirection) {
    /** Undefined state */
    YATableSwipeDirectionNone = 0,
    /** Left to right swipe */
    YATableSwipeDirectionRight = 1,
    /** Right to left swipe */
    YATableSwipeDirectionLeft = 2
};

/**
 *  Block definition used during a swipe callback.
 *
 *  @param  cell            The cell in which the swipe is occurring.
 *  @param  translation     The point translation of the swipe.
 *
 */
typedef void (^YMTableCellDidSwipeBlock)(UITableViewCell *cell, CGPoint translation);

/**
 *  Block definition used when a swipe will change the state of the cell.
 *
 *  @param  cell            The cell in which the swipe is occurring.
 *  @param  mode            The swipe mode that the cell will transition to.
 *
 */
typedef void (^YMTableCellWillChangeModeBlock)(UITableViewCell *cell, YATableSwipeMode mode);

/**
 *  Block definition used when a swipe has changed the state of the cell.
 *
 *  @param  cell            The cell in which the swipe is occurring.
 *  @param  mode            The swipe mode that the cell has transitioned to.
 *
 */
typedef void (^YMTableCellDidChangeModeBlock)(UITableViewCell *cell, YATableSwipeMode mode);

@interface UITableViewCell (Swipe)

/** Sets the type of swipe effect. The default value is YATableSwipeEffectUnmask. */
@property (nonatomic, readwrite) YATableSwipeEffect swipeEffect;

/** This flags determines if multipe cells can be swiped at one time. The default value is NO. */
@property (nonatomic, readwrite) BOOL allowMultiple;

/** The background color for the container view of the swiped view. The default value is lightGray. */
@property (nonatomic, strong) UIColor *swipeContainerViewBackgroundColor;

/** A content offset delta that determines the snap threshold during a left to right swipe. The default value is 0. */
@property (nonatomic, readwrite) CGFloat rightSwipeSnapThreshold;

/** A content offset delta that determines the snap threshold during a right to left swipe. The default value is 0. */
@property (nonatomic, readwrite) CGFloat leftSwipeSnapThreshold;

/** The current swipe state of the cell. */
@property (nonatomic, readwrite) YATableSwipeMode currentSwipeMode;

/** This block is called during a swipe. */
@property (nonatomic, strong) YMTableCellDidSwipeBlock swipeBlock;

/** This block is called when a swipe will change the state of the cell. */
@property (nonatomic, strong) YMTableCellWillChangeModeBlock modeWillChangeBlock;

/** This block is called when a swipe has changed the state of the cell. */
@property (nonatomic, strong) YMTableCellDidChangeModeBlock modeChangedBlock;

/** Enable or disable swiping, defaults to YES **/
@property (nonatomic, assign) BOOL swipingEnabled;

/** 
 *
 * @return BOOL to specify if a swipe is occurring
 *
 */
- (BOOL) cellIsBeingSwiped;

/**
 *  Adds the view exposed during a right to left swipe.
 *
 *  @param  view    The view beneath the cell which is exposed during a right to left swipe.
 *
 */
- (void)addRightView:(UIView *)view;

/**
 *  Adds the view exposed during a left to right swipe.
 *
 *  @param  view    The view beneath the cell which is exposed during a left to right swipe.
 *
 */
- (void)addLeftView:(UIView *)view;

/**
 *  Resets the cell to its original state in which no swipe views are exposed.
 *
 *  @param  completion      This callback is executed after the animation sequence completes.
 *                          If the finished flag is true, then the animation has completed.
 *                          If the finished flag is false, then the animation will complete in the next run loop cycle.
 *  @param  animate         BOOL flag determines if a cell animation will occur or not. 
 *
 */
- (void)resetSwipe:(void (^)(BOOL finished))completion withAnimation:(BOOL)animate;


@end
