//
//  YMTwoButtonSwipeView.h
//  YMSwipeTableViewCell
//
//  Created by aluong on 8/25/15.
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewCell+Swipe.h"
#import "OBAStackedButton.h"

@interface YMTwoButtonSwipeView : UIView

@property (nonatomic, strong) OBAStackedButton *leftButton;
@property (nonatomic, strong) OBAStackedButton *rightButton;

@property (nonatomic, copy) void (^leftButtonTappedActionBlock)(void);
@property (nonatomic, copy) void (^rightButtonTappedActionBlock)(void);


- (void)didSwipeWithTranslation:(CGPoint)translation;
- (void)didChangeMode:(YATableSwipeMode)mode;

@end
