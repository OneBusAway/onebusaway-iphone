//
//  OBACreditsViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/15/12.
//
//

#import <UIKit/UIKit.h>
@import WebKit;
NS_ASSUME_NONNULL_BEGIN

@interface OBACreditsViewController : UIViewController <UIWebViewDelegate>
@property(nonatomic,strong) IBOutlet WKWebView *webView;
@end

NS_ASSUME_NONNULL_END