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
    
    [self updateBackButton];
}

- (void)updateBackButton {
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(handleBack)];
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)loadURL {
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void)loadView {
    self.view = self.webView;
    [self loadURL];
}

- (void)handleBack {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (UIWebView*)webView {
    if(!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _webView.delegate = self;
        _webView.scalesPageToFit = YES;
    }
    return _webView;
}

@end
