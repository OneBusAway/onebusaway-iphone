//
//  BTBalloon.h
//
//  Created by Cameron Cooke on 10/03/2014.
//  Copyright (c) 2014 Brightec Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import <UIKit/UIKit.h>


@interface BTBalloon : UIView

// styling
@property (strong, nonatomic) UIFont *buttonFont UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *buttonTextColor UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *buttonBackgroundColor UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *balloonBackgroundColor UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIFont *textFont UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *textColor UI_APPEARANCE_SELECTOR;

+ (instancetype)sharedInstance;

- (void)showWithTitle:(NSString *)title image:(UIImage *)image;
- (void)showWithTitle:(NSString *)title image:(UIImage *)image anchorToView:(UIView *)view;
- (void)showWithTitle:(NSString *)title image:(UIImage *)image anchorToView:(UIView *)view buttonTitle:(NSString *)buttonTitle buttonCallback:(void (^)(void))callbackBlock;
- (void)showWithTitle:(NSString *)title image:(UIImage *)image anchorToView:(UIView *)view buttonTitle:(NSString *)buttonTitle buttonCallback:(void (^)(void))callbackBlock afterDelay:(NSTimeInterval)delay;

- (void)updateTitle:(NSString *)title image:(UIImage *)image button:(NSString *)buttonTitle buttonCallback:(void (^)(void))callbackBlock;
- (void)anchorToView:(UIView *)view;
- (void)hide;
- (void)hideWithAnimation:(BOOL)animated;
- (void)show;
- (void)showWithAnimation:(BOOL)animated;
@end
