//
//  ApptentiveBannerViewController.m
//  TestBanner
//
//  Created by Frank Schmitt on 6/17/15.
//  Copyright (c) 2015 Apptentive. All rights reserved.
//

#import "ApptentiveBannerViewController.h"
#import "Apptentive_Private.h"

#define DISPLAY_DURATION 3.0
#define ANIMATION_DURATION 0.33


@interface ApptentiveBannerViewController ()

@property (strong, nonatomic) ApptentiveBannerViewController *cyclicReference;
@property (strong, nonatomic) NSTimer *hideTimer;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) IBOutlet UIView *bannerView;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet ApptentiveNetworkImageView *imageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconSpacingConstraint;

@end


@implementation ApptentiveBannerViewController

+ (instancetype)bannerWithImageURL:(NSURL *)imageURL title:(NSString *)title message:(NSString *)message {
	static ApptentiveBannerViewController *_currentBanner;

	if (_currentBanner != nil) {
		[_currentBanner hide:self];
	}

	ApptentiveBannerViewController *banner = [[Apptentive storyboard] instantiateViewControllerWithIdentifier:@"Banner"];

	banner.imageURL = imageURL;
	banner.titleText = title;
	banner.messageText = message;

	return banner;
}

- (void)show {
	UIWindow *mainWindow = [UIApplication sharedApplication].delegate.window;

	self.window = [[UIWindow alloc] initWithFrame:mainWindow.bounds];
	self.window.rootViewController = self;
	self.window.windowLevel = UIWindowLevelAlert;

	[self.window makeKeyAndVisible];

	self.hideTimer = [NSTimer scheduledTimerWithTimeInterval:DISPLAY_DURATION target:self selector:@selector(hide:) userInfo:nil repeats:NO];

	self.topConstraint.constant = -CGRectGetHeight(self.bannerView.bounds);
	[self.view layoutIfNeeded];

	self.topConstraint.constant = 0;

	[UIView animateWithDuration:ANIMATION_DURATION animations:^{
		[self.view layoutIfNeeded];
		self.window.frame = self.bannerView.frame;
	}];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	self.imageURL = _imageURL;
	self.titleText = _titleText;
	self.messageText = _messageText;
}

- (void)dealloc {
	self.window.rootViewController = nil;
	[self.hideTimer invalidate];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations {
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
#endif
	return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
	return [UIApplication sharedApplication].statusBarHidden;
}

- (void)viewDidLayoutSubviews {
	self.imageView.layer.cornerRadius = CGRectGetHeight(self.imageView.bounds) / 2.0;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[self.window resignKeyWindow];
	self.window.rootViewController = nil;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self.window makeKeyAndVisible];
	self.window.rootViewController = self;
	self.window.frame = self.bannerView.bounds;
}

- (void)setHasIcon:(BOOL)hasIcon {
	self.imageView.hidden = !hasIcon;

	if (hasIcon) {
		if (![self.bannerView.constraints containsObject:self.iconSpacingConstraint]) {
			[self.bannerView addConstraint:self.iconSpacingConstraint];
		}
		self.imageView.hidden = NO;
	} else {
		if ([self.bannerView.constraints containsObject:self.iconSpacingConstraint]) {
			[self.bannerView removeConstraint:self.iconSpacingConstraint];
		}
		self.imageView.hidden = YES;
	}
}

- (void)setImageURL:(NSURL *)imageURL {
	_imageURL = imageURL;

	self.imageView.imageURL = imageURL;
}

- (void)setTitleText:(NSString *)titleText {
	_titleText = titleText;

	self.titleLabel.text = titleText;
}

- (void)setMessageText:(NSString *)messageText {
	_messageText = messageText;

	self.messageLabel.text = messageText;
}

#pragma mark - Image view delegate

- (void)networkImageViewDidLoad:(ApptentiveNetworkImageView *)imageView {
	self.hasIcon = YES;
}

- (void)networkImageView:(ApptentiveNetworkImageView *)imageView didFailWithError:(NSError *)error {
	self.hasIcon = NO;
}

#pragma mark - Actions

- (IBAction)hide:(id)sender {
	self.topConstraint.constant = -CGRectGetHeight(self.bannerView.bounds);

	[UIView animateWithDuration:ANIMATION_DURATION animations:^{
		[self.view layoutIfNeeded];
	} completion:^(BOOL finished) {
		[self.window resignKeyWindow];
		
		self.window.rootViewController = nil;
	}];
}

- (IBAction)tap:(id)sender {
	[self.delegate userDidTapBanner:self];

	[self hide:sender];
}

@end
