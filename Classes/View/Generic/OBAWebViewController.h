@interface OBAWebViewController : UIViewController <UIWebViewDelegate> {

}

+(OBAWebViewController*)pushOntoViewController:(UIViewController*)parent withHtml:(NSString*)html withTitle:(NSString*)title;

@end