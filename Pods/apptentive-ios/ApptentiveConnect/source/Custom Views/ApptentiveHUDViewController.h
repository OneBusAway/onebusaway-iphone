//
//  ApptentiveHUDViewController.h
//  ATHUD
//
//  Created by Frank Schmitt on 3/2/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ApptentiveHUDViewController : UIViewController

@property (assign, nonatomic) NSTimeInterval interval;
@property (assign, nonatomic) NSTimeInterval animationDuration;

@property (strong, nonatomic) UILabel *textLabel;
@property (strong, nonatomic) UIImageView *imageView;

- (void)showInAlertWindow;

@end
