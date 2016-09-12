//
//  ApptentiveNetworkImageView.h
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/17/13.
//  Copyright (c) 2013 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ApptentiveNetworkImageViewDelegate;


@interface ApptentiveNetworkImageView : UIImageView <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (copy, nonatomic) NSURL *imageURL;
@property (assign, nonatomic) BOOL useCache;
@property (weak, nonatomic) id<ApptentiveNetworkImageViewDelegate> delegate;
@end

@protocol ApptentiveNetworkImageViewDelegate <NSObject>

- (void)networkImageViewDidLoad:(ApptentiveNetworkImageView *)imageView;
- (void)networkImageView:(ApptentiveNetworkImageView *)imageView didFailWithError:(NSError *)error;

@end
