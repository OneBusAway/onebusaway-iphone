//
//  AFMSlidingCell.h
//  AFMSlidingCell
//
//  Created by Artjoms Haleckis on 15/05/14.
//  Copyright (c) 2014 Ask.fm Europe, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AFMSlidingCell;

@protocol AFMSlidingCellDelegate <NSObject>

@optional
- (void)buttonsDidShowForCell:(AFMSlidingCell *)cell;
- (void)buttonsDidHideForCell:(AFMSlidingCell *)cell;
- (BOOL)shouldAllowShowingButtonsForCell:(AFMSlidingCell *)cell;

@end

@interface AFMSlidingCell : UITableViewCell

@property (nonatomic, weak) id<AFMSlidingCellDelegate> delegate;

- (void)addFirstButton:(UIButton *)button withWidth:(CGFloat)width withTappedBlock:(void (^)(AFMSlidingCell *))tappedBlock;
- (void)addSecondButton:(UIButton *)button withWidth:(CGFloat)width withTappedBlock:(void (^)(AFMSlidingCell *))tappedBlock;

- (void)showButtonViewAnimated:(BOOL)animated;
- (void)hideButtonViewAnimated:(BOOL)animated;
- (void)hideButtonsOrDoAction:(void (^)())actionToDo;

@end
