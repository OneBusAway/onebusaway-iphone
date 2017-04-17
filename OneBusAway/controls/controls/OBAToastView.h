//
//  OBAToastView.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import UIKit;

@interface OBAToastView : UIView
@property(nonatomic,strong,readonly) UILabel *label;
@property(nonatomic,strong,readonly) UIButton *button;

- (void)showWithText:(NSString*)text withCancelButton:(BOOL)withCancelButton;
- (void)dismiss;

@end
