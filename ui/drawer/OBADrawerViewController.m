//
//  OBADrawerViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBADrawerViewController.h"
#import "OBAVibrantBlurContainerView.h"
#import "UIViewController+OBAContainment.h"

@interface OBADrawerViewController ()
@property(nonatomic,strong) OBAVibrantBlurContainerView *blurContainerView;
@property(nonatomic,strong) UISegmentedControl *segmentedControl;
@property(nonatomic,weak) UIViewController *visibleViewController;
@end

@implementation OBADrawerViewController

- (instancetype)init {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"OneBusAway", @"");
        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[]];
        [self.segmentedControl addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView = self.segmentedControl;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.blurContainerView = [[OBAVibrantBlurContainerView alloc] initWithFrame:self.view.bounds];
    self.blurContainerView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.blurContainerView];
}

#pragma mark - Accessors

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers {
    _viewControllers = [viewControllers copy];

    NSArray *titles = [_viewControllers valueForKey:NSStringFromSelector(@selector(title))];
    [self.segmentedControl removeAllSegments];

    for (NSInteger i=0; i<titles.count; i++) {
        NSString *title = titles[i];
        [self.segmentedControl insertSegmentWithTitle:title atIndex:i animated:NO];
    }
    [self.segmentedControl sizeToFit];

    self.segmentedControl.selectedSegmentIndex = 0;
    [self segmentSelected:nil];
}

#pragma mark - Actions

// TODO: animate this.
- (void)segmentSelected:(id)sender {
    [self oba_removeChildViewController:self.visibleViewController];
    self.visibleViewController = self.viewControllers[self.segmentedControl.selectedSegmentIndex];
    [self oba_addChildViewController:self.visibleViewController];
}

@end
