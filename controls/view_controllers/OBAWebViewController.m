
#import "OBAWebViewController.h"
#import <SafariServices/SafariServices.h>

@interface OBAWebViewController (Private)
- (UIWebView*) webView;
@end

@implementation OBAWebViewController

+(OBAWebViewController*)pushOntoViewController:(UIViewController*)parent withHtml:(NSString*)html withTitle:(NSString*)title {
    NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBAWebViewController" owner:parent options:nil];
    OBAWebViewController* controller = wired[0];
    [controller setTitle:title];
    
    UIWebView * webView = [controller webView];
    
    [webView loadHTMLString:html baseURL:nil];
    
    [[parent navigationController] pushViewController:controller animated:YES];
    return controller;
}


#pragma mark UIViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)type {

    if (type != UIWebViewNavigationTypeLinkClicked) {
        return YES;
    }

    SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:request.URL];
    safari.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:safari animated:YES completion:nil];
    return NO;
}

@end

@implementation OBAWebViewController (Private)

-(UIWebView*)webView {
    return (UIWebView*)[self view];
}

@end

