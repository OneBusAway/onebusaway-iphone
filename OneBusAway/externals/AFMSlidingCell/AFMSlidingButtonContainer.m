//
//  AFMSlidingButtonContainer.m
//  AFMSlidingCell
//
//  Created by Artjoms Haleckis on 16/05/14.
//  Copyright (c) 2014 Ask.fm Europe, Ltd. All rights reserved.
//

#import "AFMSlidingButtonContainer.h"

@interface AFMSlidingButtonContainer ()

@property (nonatomic,strong,readwrite) UIButton *leftButton;
@property (nonatomic,strong,readwrite) UIButton *centerButton;
@property (nonatomic,strong,readwrite) UIButton *rightButton;
@property (nonatomic) CGFloat leftButtonWidth;
@property (nonatomic) CGFloat centerButtonWidth;
@property (nonatomic) CGFloat rightButtonWidth;
@property (nonatomic, copy) void (^leftButtonTappedBlock)(AFMSlidingCell *);
@property (nonatomic, copy) void (^centerButtonTappedBlock)(AFMSlidingCell *);
@property (nonatomic, copy) void (^rightButtonTappedBlock)(AFMSlidingCell *);

@end

@implementation AFMSlidingButtonContainer

#pragma mark - Custom getters and setters

- (CGFloat)bothButtonsWidth
{
    return self.leftButtonWidth + self.centerButtonWidth + self.rightButtonWidth;
}

#pragma mark - Button adding API

- (void)addLeftButton:(UIButton *)button withWidth:(CGFloat)width withTappedBlock:(void (^)(AFMSlidingCell *))tappedBlock;
{
    if ([self.leftButton isEqual:button])
        return;
    [self removeButton:self.leftButton];
    self.leftButton = button;
    self.leftButtonWidth = width;
    self.leftButtonTappedBlock = tappedBlock;
    [self addButton:button withWidth:width];
}

- (void)addCenterButton:(UIButton *)button withWidth:(CGFloat)width withTappedBlock:(void (^)(AFMSlidingCell *))tappedBlock;
{
    if ([self.centerButton isEqual:button])
        return;
    [self removeButton:self.centerButton];
    self.centerButton = button;
    self.centerButtonWidth = width;
    self.centerButtonTappedBlock = tappedBlock;
    [self addButton:button withWidth:width];
}

- (void)addRightButton:(UIButton *)button withWidth:(CGFloat)width withTappedBlock:(void (^)(AFMSlidingCell *))tappedBlock;
{
    if ([self.rightButton isEqual:button])
        return;
    [self removeButton:self.rightButton];
    self.rightButton = button;
    self.rightButtonWidth = width;
    self.rightButtonTappedBlock = tappedBlock;
    [self addButton:button withWidth:width];
}

#pragma mark - Generic button adding/removal

- (void)removeButton:(UIButton *)button
{
    [button removeFromSuperview];
}

- (void)addButton:(UIButton *)button withWidth:(CGFloat)width
{
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    CGRect frame = self.frame;
    [self addSubview:button];
    frame.size.width += width;
    self.frame = frame;
    [self positionButtons];
    [self setBackground];
}

- (void)clearButtons
{
    [self removeButton:self.leftButton];
    [self removeButton:self.centerButton];
    [self removeButton:self.rightButton];
    self.leftButton = nil;
    self.centerButton = nil;
    self.rightButton = nil;
    self.leftButtonWidth = 0;
    self.centerButtonWidth = 0;
    self.rightButtonWidth = 0;
}

#pragma mark - Button taps

- (void)buttonTapped:(UIButton *)button {
    AFMSlidingCell *parentCell = self.parentCell;

    if ([button isEqual:self.leftButton]) {
        if (self.leftButtonTappedBlock)
            self.leftButtonTappedBlock(parentCell);
    }
    else if ([button isEqual:self.centerButton]) {
        if (self.centerButtonTappedBlock)
            self.centerButtonTappedBlock(parentCell);
    }
    else {
        if (self.rightButtonTappedBlock)
            self.rightButtonTappedBlock(parentCell);
    }
}

#pragma mark - Button positioning

- (void)positionButtons {
    CGFloat maxX = 0;

    if (self.leftButton) {
        [self.leftButton setFrame:CGRectMake(0, 0, self.leftButtonWidth, self.frame.size.height)];
        maxX = self.leftButtonWidth;
    }

    if (self.centerButton) {
        self.centerButton.frame = CGRectMake(maxX, 0, self.centerButtonWidth, CGRectGetHeight(self.frame));
        maxX += self.centerButtonWidth;
    }

    if (self.rightButton) {
        [self.rightButton setFrame:CGRectMake(maxX, 0, self.rightButtonWidth, self.frame.size.height)];
    }
}

#pragma mark - Background

- (void)setBackground
{
    if (self.rightButton) {
        [self setBackgroundColor:self.rightButton.backgroundColor];
    }
    else if (self.leftButton) {
        [self setBackgroundColor:self.leftButton.backgroundColor];
    }
}

#pragma mark - Override

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self positionButtons];
}

@end
