#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAWebViewController : UIViewController <UIWebViewDelegate>
+(OBAWebViewController*)pushOntoViewController:(UIViewController*)parent withHtml:(NSString*)html withTitle:(NSString*)title;
@end

NS_ASSUME_NONNULL_END