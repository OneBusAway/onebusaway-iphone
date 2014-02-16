//
//  OBACreditsViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/15/12.
//
//

#import "OBACreditsViewController.h"

@interface OBACreditsViewController ()

@end

@implementation OBACreditsViewController

- (id)init
{
    self = [super initWithNibName:@"OBACreditsViewController" bundle:nil];
    if (self) {
        self.title = NSLocalizedString(@"Credits", @"Title of credits view controller");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *htmlString = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"credits" ofType:@"html"] encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:[NSBundle mainBundle].bundlePath]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker set:kGAIScreenName
                                       value:[NSString stringWithFormat:@"View: %@", [self class]]];
    [[GAI sharedInstance].defaultTracker
     send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSArray *nonLocalSchemes = @[@"http", @"https"];
    if (NSNotFound != [nonLocalSchemes indexOfObject:request.URL.scheme]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    else {
        return YES;
    }
}

@end
