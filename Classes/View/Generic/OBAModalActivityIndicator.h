@interface OBAModalActivityIndicator : NSObject {
	UIView * _modalView;
	UIActivityIndicatorView * _activityIndicatorView;
}

- (void) show:(UIView*)view;
- (void) hide;

@end
