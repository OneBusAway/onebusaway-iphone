//
//  AFMSlidingButtonContainer.h
//  AFMSlidingCell
//
//  Created by Artjoms Haleckis on 16/05/14.
//  Copyright (c) 2014 Ask.fm Europe, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AFMSlidingCell;

@interface AFMSlidingButtonContainer : UIView

@property (nonatomic, readonly) CGFloat bothButtonsWidth;
@property (nonatomic, weak) AFMSlidingCell *parentCell;

@property(nonatomic,strong,readonly) UIButton *leftButton;
@property(nonatomic,strong,readonly) UIButton *centerButton;
@property(nonatomic,strong,readonly) UIButton *rightButton;

- (void)addLeftButton:(UIButton *)button withWidth:(CGFloat)width withTappedBlock:(void (^)(AFMSlidingCell *))tappedBlock;
- (void)addCenterButton:(UIButton *)button withWidth:(CGFloat)width withTappedBlock:(void (^)(AFMSlidingCell *))tappedBlock;
- (void)addRightButton:(UIButton *)button withWidth:(CGFloat)width withTappedBlock:(void (^)(AFMSlidingCell *))tappedBlock;
- (void)clearButtons;

@end
