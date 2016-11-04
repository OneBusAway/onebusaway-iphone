//
//  YMOneButtonSwipeView.h
//  YMSwipeTableViewCell
//
//  Created by aluong on 8/27/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewCell+Swipe.h"

@interface YMOneButtonSwipeView : UIView

@property (nonatomic, strong) UIButton *aButton;
@property (nonatomic, copy) void (^buttonTappedActionBlock)(void);
- (void)didSwipeWithTranslation:(CGPoint)translation;
- (void)didChangeMode:(YATableSwipeMode)mode;
@end
