/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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

