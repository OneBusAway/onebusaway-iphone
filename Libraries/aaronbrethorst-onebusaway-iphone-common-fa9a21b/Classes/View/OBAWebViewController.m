#import "OBAWebViewController.h"


@interface OBAWebViewController (Private)

-(UIWebView*) webView;

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark UIWebViewDelegate

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
	
	if( inType == UIWebViewNavigationTypeLinkClicked ) {
		[[UIApplication sharedApplication] openURL:[inRequest URL]];
		return NO;
	}
	else {
		return YES;
	}
}

@end

@implementation OBAWebViewController (Private)

-(UIWebView*)webView {
	return (UIWebView*)[self view];
}

@end

