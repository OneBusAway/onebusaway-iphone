//
//  OBAStopWebViewController.m
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 2/12/14.
//  Copyright (c) 2014 OneBusAway. All rights reserved.
//

#import "OBAStopWebViewController.h"

@interface OBAStopWebViewController ()

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) BOOL onLastView;

@end

@implementation OBAStopWebViewController

- (id)initWithURL:(NSURL*)url {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    [self.view addSubview:self.webView];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"") style:UIBarButtonItemStyleDone target:self action:@selector(handleBack)];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

#pragma mark - Actions

- (void)handleBack {
    if ([self.webView canGoBack] && !self.onLastView) {
        [self.webView goBack];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.absoluteString rangeOfString:@"http://stopinfo.pugetsound.onebusaway.org/about/entry/"].location != NSNotFound) {
        self.onLastView = YES;
    }
    return YES;
}
@end
