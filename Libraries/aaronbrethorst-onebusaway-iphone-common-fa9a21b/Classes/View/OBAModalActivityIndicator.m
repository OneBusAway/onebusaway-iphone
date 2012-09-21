#import "OBAModalActivityIndicator.h"


@implementation OBAModalActivityIndicator


- (void) show:(UIView*)view {
	
	_modalView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
	_modalView.alpha = 0.5;
	_modalView.backgroundColor = [UIColor grayColor];
	_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]; 
	[_modalView addSubview:_activityIndicatorView];   
    _activityIndicatorView.center = _modalView.center;  
    [view addSubview:_modalView];  
    [view bringSubviewToFront:_modalView];  
    [_activityIndicatorView startAnimating];  
}

- (void) hide {
	[_modalView removeFromSuperview];
	_modalView = nil;
	_activityIndicatorView = nil;
}

@end
