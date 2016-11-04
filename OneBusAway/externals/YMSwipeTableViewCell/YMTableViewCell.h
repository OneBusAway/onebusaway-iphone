//
//  YMTableViewCell.h
//  YMSwipeTableViewCell
//
//  Created by aluong on 8/26/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewCell+Swipe.h"

extern const NSInteger YMTableViewCellTwoButtonSwipeViewTrashButtonIndex;
extern const NSInteger YMTableViewCellTwoButtonSwipeViewUndoButtonIndex;
extern const NSInteger YMTableViewCellHeight;

@protocol YMTableViewCellDelegate;

@interface YMTableViewCell : UITableViewCell

@property (nonatomic, copy) void (^swipeRightCompleteActionBlock) (BOOL undo);
@property (nonatomic, copy) void (^swipeLeftCompleteActionBlock) (BOOL undo);
@property (nonatomic, copy) void (^leftButtonTappedActionBlock)(void);
@property (nonatomic, copy) void (^rightButtonTappedActionBlock)(void);
@property (nonatomic, weak) id<YMTableViewCellDelegate> delegate;

@end

@protocol YMTableViewCellDelegate
- (void)swipeableTableViewCell:(YMTableViewCell *)cell didTriggerLeftViewButtonWithIndex:(NSInteger)index;
- (void)swipeableTableViewCell:(YMTableViewCell *)cell didTriggerRightViewButtonWithIndex:(NSInteger)index;
- (void)swipeableTableViewCell:(YMTableViewCell *)cell didCompleteSwipe:(YATableSwipeMode)swipeMode;
@end
