//
//  ApptentiveBannerViewController.h
//  TestBanner
//
//  Created by Frank Schmitt on 6/17/15.
//  Copyright (c) 2015 Apptentive. All rights reserved.
//

#import "ApptentiveNetworkImageView.h"

@protocol ApptentiveBannerViewControllerDelegate;


@interface ApptentiveBannerViewController : UIViewController <ApptentiveNetworkImageViewDelegate>

@property (weak, nonatomic) id<ApptentiveBannerViewControllerDelegate> delegate;
@property (strong, nonatomic) NSURL *imageURL;
@property (copy, nonatomic) NSString *titleText;
@property (copy, nonatomic) NSString *messageText;

+ (instancetype)bannerWithImageURL:(NSURL *)imageURL title:(NSString *)title message:(NSString *)message;
- (void)show;

@end

@protocol ApptentiveBannerViewControllerDelegate <NSObject>

- (void)userDidTapBanner:(ApptentiveBannerViewController *)banner;

@end
