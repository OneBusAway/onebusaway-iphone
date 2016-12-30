//
//  AFMSlidingCell.m
//  AFMSlidingCell
//
//  Created by Artjoms Haleckis on 15/05/14.
//  Copyright (c) 2014 Ask.fm Europe, Ltd. All rights reserved.
//

#import "AFMSlidingCell.h"
#import "AFMSlidingButtonContainer.h"

static const CGFloat kAnimationDuration = 0.2f;

typedef NS_ENUM(NSUInteger, AFMSlidingCellState) {
    kCoolSlidingStateButtonsHidden = 0,
    kCoolSlidingStateButtonsPartiallyVisible,
    kCoolSlidingStateButtonsBecomingActive,
    kCoolSlidingStateButtonsActive
};

@interface AFMSlidingCell () <UIScrollViewDelegate,  UIGestureRecognizerDelegate>

@property (nonatomic) AFMSlidingCellState cellState;
@property (nonatomic) AFMSlidingButtonContainer *buttonContainer;
@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic) CGPoint defaultLayerPositionForHiddenButtons;
@property (nonatomic) CGPoint defaultLayerPositionForShownButtons;
@property (nonatomic) CGPoint defaultContainerPosition;
@property (nonatomic) CGPoint actualPanPosition;

@end

@implementation AFMSlidingCell

#pragma mark - Setting buttons

- (void)addFirstButton:(UIButton *)button
            withWidth:(CGFloat)width
      withTappedBlock:(void (^)(AFMSlidingCell *))tappedBlock
{
    [self.buttonContainer addLeftButton:button withWidth:width withTappedBlock:tappedBlock];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)addSecondButton:(UIButton *)button
             withWidth:(CGFloat)width
       withTappedBlock:(void (^)(AFMSlidingCell *))tappedBlock
{
    [self.buttonContainer addRightButton:button withWidth:width withTappedBlock:tappedBlock];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Initializers

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    [self.tapGesture setDelegate:nil];
    [self.tapGesture setEnabled:NO];
    [self.panGesture setDelegate:nil];
    [self.panGesture setEnabled:NO];
}

#pragma mark - Setup

- (void)setup
{
    [self setupGestures];
    [self setupButtonContainer];
    [self setupContentView];
}

- (void)setupGestures
{
    // Pan gesture for showing/hiding buttons
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panGesture.delegate = self;
    [self addGestureRecognizer:self.panGesture];
    // Tap gesture for hiding buttons by tap, when buttons are active or when requested
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    self.tapGesture.delegate = self;
    [self addGestureRecognizer:self.tapGesture];
}

- (void)setupButtonContainer
{
    // Button container will position buttons. Will be positioned properly in layoutSubviews
    CGRect containerFrame = CGRectOffset(self.frame, self.frame.size.width, 0);
    self.buttonContainer = [[AFMSlidingButtonContainer alloc] initWithFrame:containerFrame];
    self.buttonContainer.parentCell = self;
    [self insertSubview:self.buttonContainer belowSubview:self.contentView];
    [self.buttonContainer setHidden:YES];
}

- (void)setupContentView
{
    if (!self.backgroundColor)
        self.backgroundColor = [UIColor whiteColor];

    if (!self.contentView.backgroundColor) {
        // By default contentView is transparent, setting it's background to cell's
        [self.contentView setBackgroundColor:self.backgroundColor];
    }

    [self bringSubviewToFront:self.contentView];
}

#pragma mark - UIGestureRecognizer delegate and handling

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isEqual:self.panGesture])
        return [self panGestureShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer];
    if ([gestureRecognizer isEqual:self.tapGesture])
        return [self tapGestureShouldBegin:(UITapGestureRecognizer *)gestureRecognizer];
    return YES;
}

- (BOOL)tapGestureShouldBegin:(UITapGestureRecognizer *)gestureRecognizer
{
    // Tap gesture is needed only when buttons are shown
    BOOL isLocalGesture = [gestureRecognizer isEqual:self.tapGesture] || [gestureRecognizer isEqual:self.panGesture];
    return isLocalGesture && self.cellState == kCoolSlidingStateButtonsActive;
}

- (BOOL)panGestureShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    id<AFMSlidingCellDelegate> delegate = self.delegate;

    if (self.cellState == kCoolSlidingStateButtonsHidden) {
        if ([delegate respondsToSelector:@selector(shouldAllowShowingButtonsForCell:)] &&
            ![delegate shouldAllowShowingButtonsForCell:self])
            return NO;
    }
    CGPoint translation = [gestureRecognizer translationInView:[self superview]];
    // We don't need vertical pan
    return fabs(translation.x) > fabs(translation.y);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return self.cellState != kCoolSlidingStateButtonsActive;
}

-(void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self handlePanBegan];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self handlePanChangedWithTranslation:[recognizer translationInView:self]];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self handlePanEnded];
    }
}

- (void)handlePanBegan
{
    [self.buttonContainer setHidden:NO];
    // Saving default positions for hidden and shown buttons to restore state at any moment
    if (self.cellState != kCoolSlidingStateButtonsHidden)
        self.defaultLayerPositionForShownButtons = self.contentView.layer.position;
    // Also must remember, which of the positions matters now
    if (self.cellState == kCoolSlidingStateButtonsActive)
        self.actualPanPosition = self.defaultLayerPositionForShownButtons;
    else
        self.actualPanPosition = self.defaultLayerPositionForHiddenButtons;
}

- (void)handlePanEnded
{
    switch (self.cellState) {
        case kCoolSlidingStateButtonsPartiallyVisible:
            [self hideButtonViewAnimated:YES];
            break;
        case kCoolSlidingStateButtonsBecomingActive:
            [self showButtonViewAnimated:YES];
            break;
        case kCoolSlidingStateButtonsActive:
            [self bounceButtons];
            break;
        default:
            break;
    }
}

- (void)handlePanChangedWithTranslation:(CGPoint)translation;
{
    CGFloat dx = translation.x;
    // Allowing only one-way pan, if buttons hidden
    if (self.cellState == kCoolSlidingStateButtonsHidden && dx > 0)
        return;

    CGFloat positionX = self.actualPanPosition.x + dx;
    // Disabling bounce to the right
    if (positionX > self.frame.size.width / 2.f)
        positionX = self.frame.size.width / 2.f;
    // Moving contentView's layer accordingly. This ensures that it stays the same size, is moved within the
    // cell, and buttons are clickable, as they are included into view's frame
    self.contentView.layer.position = CGPointMake(positionX, self.contentView.layer.position.y);

    CGFloat delta = self.defaultLayerPositionForHiddenButtons.x - self.contentView.layer.position.x;
    [self handlePanDeltaChangeWithDelta:delta];
}

- (void)handlePanDeltaChangeWithDelta:(CGFloat)delta
{
    if (delta > self.buttonContainer.bothButtonsWidth) {
        // If scrolled more than both buttons take, "stretching" last button
        CGRect frame = self.buttonContainer.frame;
        frame.origin.x = self.frame.size.width - delta;
        [self.buttonContainer setFrame:frame];
    }
    CGFloat pivot = self.buttonContainer.bothButtonsWidth / 2.f;
    if (delta >= pivot) {
        // If scrolled over more than a half of buttons' view, buttons are ready to become fully shown
        // This does not apply if buttons are already active
        if (self.cellState != kCoolSlidingStateButtonsActive)
            self.cellState = kCoolSlidingStateButtonsBecomingActive;
    } else {
        // If scrolled over less than a half of buttons' view, buttons will be hidden on release
        self.cellState = kCoolSlidingStateButtonsPartiallyVisible;
    }
}

- (void)handleTap
{
    [self hideButtonViewAnimated:YES];
}

#pragma mark - Showing/hiding buttons

- (void)showButtonViewAnimated:(BOOL)animated {
    id<AFMSlidingCellDelegate> delegate = self.delegate;

    [self.buttonContainer setHidden:NO];
    CGPoint activeContentViewPosition = CGPointMake(self.defaultLayerPositionForHiddenButtons.x -
                                                    self.buttonContainer.bothButtonsWidth,
                                                    self.defaultLayerPositionForHiddenButtons.y);
    CGRect buttonContainerFrame = self.buttonContainer.frame;
    buttonContainerFrame.origin.x = self.frame.size.width - self.buttonContainer.bothButtonsWidth;
    CGFloat animationDuration = animated ? kAnimationDuration : 0;
    [UIView animateWithDuration:animationDuration animations:^{
        self.contentView.layer.position = activeContentViewPosition;
        [self.buttonContainer setFrame:buttonContainerFrame];
    } completion:^(BOOL finished) {
        self.cellState = kCoolSlidingStateButtonsActive;
        if ([delegate respondsToSelector:@selector(buttonsDidShowForCell:)])
            [delegate performSelector:@selector(buttonsDidShowForCell:) withObject:self];
    }];
}

- (void)hideButtonViewAnimated:(BOOL)animated {
    id<AFMSlidingCellDelegate> delegate = self.delegate;

    CGFloat animationDuration = animated ? kAnimationDuration : 0;
    [UIView animateWithDuration:animationDuration animations:^{
        self.contentView.layer.position = self.defaultLayerPositionForHiddenButtons;
    } completion:^(BOOL finished) {
        self.cellState = kCoolSlidingStateButtonsHidden;
        [self.buttonContainer setHidden:YES];
        if ([delegate respondsToSelector:@selector(buttonsDidHideForCell:)])
            [delegate performSelector:@selector(buttonsDidHideForCell:) withObject:self];
    }];
}

- (void)bounceButtons
{
    CGRect frame = self.buttonContainer.frame;
    frame.origin = self.defaultContainerPosition;
    [UIView animateWithDuration:kAnimationDuration animations:^{
        self.buttonContainer.frame = frame;
        self.contentView.layer.position = self.defaultLayerPositionForShownButtons;
    }];
}

- (void)hideButtonsOrDoAction:(void (^)())actionToDo
{
    switch (self.cellState) {
        case kCoolSlidingStateButtonsHidden:
            if (actionToDo)
                actionToDo();
            break;
        case kCoolSlidingStateButtonsActive:
            [self hideButtonViewAnimated:YES];
            break;
        default:
            break;
    }
}

#pragma mark - Override

- (void)prepareForReuse
{
    [super prepareForReuse];
    // Stopping all cell animations, just in case
    [self.layer removeAllAnimations];
    [self hideButtonViewAnimated:NO];
    self.contentView.layer.position = self.defaultLayerPositionForHiddenButtons;
    [self.buttonContainer clearButtons];
    [self.buttonContainer setHidden:YES];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    // Positioning container when we have all proper sizes
    CGRect frame = self.buttonContainer.frame;
    frame.size.height = self.frame.size.height;
    self.defaultContainerPosition = CGPointMake(self.frame.size.width - self.buttonContainer.bothButtonsWidth,
                                                frame.origin.y);
    frame.origin = self.defaultContainerPosition;
    [self.buttonContainer setFrame:frame];

    self.defaultLayerPositionForHiddenButtons = self.contentView.layer.position;
}

@end
