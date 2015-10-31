
NS_ASSUME_NONNULL_BEGIN

@interface OBAModalActivityIndicator : NSObject {
    UIView * _modalView;
    UIActivityIndicatorView * _activityIndicatorView;
}

- (void) show:(UIView*)view;
- (void) hide;

@end

NS_ASSUME_NONNULL_END