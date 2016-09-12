//
//  ApptentiveHUDViewController.m
//  ATHUD
//
//  Created by Frank Schmitt on 3/2/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveHUDViewController.h"
#import "ApptentivePassThroughWindow.h"


@interface ApptentiveHUDViewController ()

@property (strong, nonatomic) IBOutlet UIView *HUDView;
@property (strong, nonatomic) UIWindow *hostWindow;
@property (strong, nonatomic) UIWindow *shadowWindow;
@property (strong, nonatomic) NSTimer *hideTimer;
@property (strong, nonatomic) UIGestureRecognizer *tapGestureRecognizer;

@end

static ApptentiveHUDViewController *currentHUD;


@implementation ApptentiveHUDViewController

- (void)loadView {
	self.view = [[UIView alloc] initWithFrame:CGRectZero];
	self.view.backgroundColor = [UIColor clearColor];

	UIView *contentView;
	if ([UIVisualEffectView class]) {
		UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
		self.HUDView = blurView;
		contentView = blurView.contentView;
	} else {
		self.HUDView = [[UIView alloc] initWithFrame:CGRectZero];
		self.HUDView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
		contentView = self.HUDView;
	}

	self.HUDView.translatesAutoresizingMaskIntoConstraints = NO;
	self.HUDView.layer.cornerRadius = 12.0;
	self.HUDView.layer.masksToBounds = YES;

	[self.view addSubview:self.HUDView];

	[self.view addConstraints:@[
		[NSLayoutConstraint constraintWithItem:self.HUDView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
		[NSLayoutConstraint constraintWithItem:self.HUDView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]
	]];

	self.textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.textLabel.textColor = [UIColor whiteColor];
	self.textLabel.font = [UIFont systemFontOfSize:15.0];
	self.textLabel.textAlignment = NSTextAlignmentCenter;
	self.textLabel.numberOfLines = 0;
	self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
	self.textLabel.preferredMaxLayoutWidth = 200;

	self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;

	self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
	self.imageView.translatesAutoresizingMaskIntoConstraints = NO;

	[contentView addSubview:self.textLabel];
	[contentView addSubview:self.imageView];

	NSDictionary *views = @{ @"image": self.imageView,
		@"label": self.textLabel };

	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(44)-[image]-(36)-[label]-(44)-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:views]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=44)-[image]-(>=44)-|" options:0 metrics:nil views:views]];
	[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=44)-[label]-(>=44)-|" options:0 metrics:nil views:views]];

	[contentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide:)]];
}

- (void)showInAlertWindow {
	self.interval = self.interval ?: 2.0;
	self.animationDuration = fmin(self.animationDuration ?: 0.25, self.interval / 2.0);

	self.hostWindow = [[ApptentivePassThroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.hostWindow.hidden = NO;

	self.hostWindow.rootViewController = self;

	self.hostWindow.windowLevel = UIWindowLevelAlert;
	self.hostWindow.backgroundColor = [UIColor clearColor];
	self.hostWindow.frame = [UIScreen mainScreen].bounds;

	self.HUDView.alpha = 0.0;
	[UIView animateWithDuration:self.animationDuration animations:^{
		self.HUDView.alpha = 1;
	}];

	self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:self.interval target:self selector:@selector(hide:) userInfo:nil repeats:NO];
}

- (IBAction)hide:(id)sender {
	[self.hideTimer invalidate];
	[UIView animateWithDuration:self.animationDuration animations:^{
		self.HUDView.alpha = 0;
	} completion:^(BOOL finished) {
		self.hostWindow.hidden = YES;
		self.hostWindow = nil;
	}];
}

- (BOOL)shouldAutorotate {
	return YES;
}

@end
