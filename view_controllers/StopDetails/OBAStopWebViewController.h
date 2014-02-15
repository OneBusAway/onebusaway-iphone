//
//  OBAStopWebViewController.h
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 2/12/14.
//  Copyright (c) 2014 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBAStopWebViewController : UIViewController <UIWebViewDelegate>

- (id)initWithURL:(NSURL*)url;

@end
