/* 
 
 Copyright 2012 Juan-Carlos Mendez (jcmendez@alum.mit.edu)
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. 
 */

#import "JCMSegmentPageController.h"

static const float JCM_TAB_BAR_HEIGHT = 44.0f;

@interface JCMSegmentPageController ()
@property (strong, nonatomic, readwrite) UIView *headerContainerView;
@property(strong) UISegmentedControl *segmentedControl;
@property(strong) UIView *contentContainerView;
@end

@implementation JCMSegmentPageController

- (id)init {
    self = [super init];
    
    if (self) {
        self.tabLocation = JCMSegmentTabLocationBottom;
        self.headerContainerViewClass = [UIView class];
        self.headerContainerView = nil;
    }
    return self;
}

- (void)removeAllSegments {
  [self.segmentedControl removeAllSegments];
}

- (void)addSegments {
    for (int i=0; i<self.viewControllers.count; i++) {
        UIViewController *viewController = [self.viewControllers objectAtIndex:i];
        [self.segmentedControl insertSegmentWithTitle:viewController.title atIndex:i animated:NO];
    }
}

- (void)reloadTabButtons {
	[self removeAllSegments];
	[self addSegments];
    // TODO -- Do I need this???
	NSUInteger lastIndex = _selectedIndex;
	_selectedIndex = NSNotFound;
	self.selectedIndex = lastIndex;
}

- (UIView*)headerContainerView {
    @synchronized(self) {
        if (!_headerContainerView) {
            _headerContainerView = [[self.headerContainerViewClass alloc] initWithFrame:CGRectZero];
        }
        return _headerContainerView;
    }
}

/**
 * When the view loads, we set the header, and on it, the segmented control that will control
 * the page being displayed
 */
- (void)viewDidLoad {
	[super viewDidLoad];

	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self.headerContainerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), JCM_TAB_BAR_HEIGHT);
    
    CGRect segmentedControlRect = CGRectInset(self.headerContainerView.frame, 5.0, 5.0);
    self.segmentedControl = [[UISegmentedControl alloc] initWithFrame:segmentedControlRect];
    self.segmentedControl.momentary = NO;
    self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [self.segmentedControl addTarget:self action:@selector(tabButtonPressed:) forControlEvents:UIControlEventValueChanged];

    [self.headerContainerView addSubview:self.segmentedControl];
	[self.view addSubview:self.headerContainerView];

	self.contentContainerView = [[UIView alloc] initWithFrame:CGRectZero];
	[self.view addSubview:self.contentContainerView];

	[self reloadTabButtons];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect tabContainerRect = CGRectZero;
    CGRect contentContainerRect = CGRectZero;
    
    if (JCMSegmentTabLocationTop == self.tabLocation) {
        tabContainerRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), JCM_TAB_BAR_HEIGHT);
        contentContainerRect = CGRectMake(0, JCM_TAB_BAR_HEIGHT, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - JCM_TAB_BAR_HEIGHT);
    }
    else {
        tabContainerRect = CGRectMake(0, CGRectGetHeight(self.view.bounds) - JCM_TAB_BAR_HEIGHT, CGRectGetWidth(self.view.bounds), JCM_TAB_BAR_HEIGHT);
        contentContainerRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - JCM_TAB_BAR_HEIGHT);
    }
    
    self.headerContainerView.frame = tabContainerRect;
    self.contentContainerView.frame = contentContainerRect;
    self.segmentedControl.frame = CGRectInset(self.headerContainerView.bounds, 5.0, 5.0);
    self.segmentedControl.frame = CGRectOffset(self.segmentedControl.frame, 0, 1);
}

- (void)viewDidUnload {
	[super viewDidUnload];
	self.headerContainerView = nil;
	self.contentContainerView = nil;
	self.segmentedControl = nil;
}

- (void)dealloc {
  self.viewControllers = nil;
  self.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Only rotate if all child view controllers agree on the new orientation.
	for (UIViewController *viewController in self.viewControllers) {
		if (![viewController shouldAutorotateToInterfaceOrientation:interfaceOrientation])
			return NO;
	}
	return YES;
}

- (void)setViewControllers:(NSArray *)newViewControllers {
	NSAssert(!newViewControllers || [newViewControllers count] >= 2, @"JCMSegmentPageController requires at least two view controllers");

	UIViewController *oldSelectedViewController = self.selectedViewController;

	// Remove the old child view controllers.
	for (UIViewController *viewController in self.viewControllers) {
		[viewController willMoveToParentViewController:nil];
		[viewController removeFromParentViewController];
	}

	_viewControllers = [newViewControllers copy];

    if (_viewControllers) {
        // This follows the same rules as UITabBarController for trying to
        // re-select the previously selected view controller.
        NSUInteger newIndex = [self.viewControllers indexOfObject:oldSelectedViewController];
        if (NSNotFound != newIndex) {
            _selectedIndex = newIndex;
        }
        else if (newIndex < [_viewControllers count]) {
            _selectedIndex = newIndex;
        }
        else {
            _selectedIndex = 0;
        }

        // Add the new child view controllers.
        for (UIViewController *viewController in _viewControllers) {
            [self addChildViewController:viewController];
            [viewController didMoveToParentViewController:self];
        }
        
        if ([self isViewLoaded]) {
            [self reloadTabButtons];
        }
    }
}

- (void)setSelectedIndex:(NSUInteger)newSelectedIndex {
	[self setSelectedIndex:newSelectedIndex animated:NO];
}

- (void)setSelectedIndex:(NSUInteger)newSelectedIndex animated:(BOOL)animated {
	NSAssert(newSelectedIndex < [self.viewControllers count], @"View controller index out of bounds");

	if ([self.delegate respondsToSelector:@selector(segmentPageController:shouldSelectViewController:atIndex:)]) {
		UIViewController *toViewController = [self.viewControllers objectAtIndex:newSelectedIndex];
		if (![self.delegate segmentPageController:self shouldSelectViewController:toViewController atIndex:newSelectedIndex]) {
			return;
        }
	}

	if (![self isViewLoaded]) {
		_selectedIndex = newSelectedIndex;
	}
	else if (_selectedIndex != newSelectedIndex) {
		UIViewController *fromViewController = nil;
		UIViewController *toViewController = nil;

		NSUInteger oldSelectedIndex = _selectedIndex;
		_selectedIndex = newSelectedIndex;

		if (_selectedIndex != NSNotFound) {
            [self.segmentedControl setSelectedSegmentIndex:_selectedIndex];
			toViewController = self.selectedViewController;
		}

		if (toViewController == nil) { // don't animate
			[fromViewController.view removeFromSuperview];
		}
		else if (fromViewController == nil) { // don't animate
			toViewController.view.frame = self.contentContainerView.bounds;
			[self.contentContainerView addSubview:toViewController.view];

			if ([self.delegate respondsToSelector:@selector(segmentPageController:didSelectViewController:atIndex:)]) {
				[self.delegate segmentPageController:self didSelectViewController:toViewController atIndex:newSelectedIndex];
            }
		} else if (animated) {
			CGRect rect = self.contentContainerView.bounds;
			if (oldSelectedIndex < newSelectedIndex)
				rect.origin.x = rect.size.width;
			else
				rect.origin.x = -rect.size.width;

			toViewController.view.frame = rect;
			self.headerContainerView.userInteractionEnabled = NO;

			[self transitionFromViewController:fromViewController
				toViewController:toViewController
				duration:0.3
				options:UIViewAnimationOptionLayoutSubviews | UIViewAnimationOptionCurveEaseOut
				animations:^ {
					CGRect rect = fromViewController.view.frame;
					if (oldSelectedIndex < newSelectedIndex)
						rect.origin.x = -rect.size.width;
					else
						rect.origin.x = rect.size.width;

					fromViewController.view.frame = rect;
					toViewController.view.frame = self.contentContainerView.bounds;
				}
				completion:^(BOOL finished) {
					self.headerContainerView.userInteractionEnabled = YES;

					if ([self.delegate respondsToSelector:@selector(segmentPageController:didSelectViewController:atIndex:)])
						[self.delegate segmentPageController:self didSelectViewController:toViewController atIndex:newSelectedIndex];
				}];
		} else { // not animated
			[fromViewController.view removeFromSuperview];

			toViewController.view.frame = self.contentContainerView.bounds;
			[self.contentContainerView addSubview:toViewController.view];

			if ([self.delegate respondsToSelector:@selector(segmentPageController:didSelectViewController:atIndex:)])
				[self.delegate segmentPageController:self didSelectViewController:toViewController atIndex:newSelectedIndex];
		}
	}
    
    self.title = self.selectedViewController.title;
}

- (UIViewController *)selectedViewController {
	if (self.selectedIndex != NSNotFound)
		return [self.viewControllers objectAtIndex:self.selectedIndex];
	else
		return nil;
}

- (void)setSelectedViewController:(UIViewController *)newSelectedViewController {
	[self setSelectedViewController:newSelectedViewController animated:NO];
}

- (void)setSelectedViewController:(UIViewController *)newSelectedViewController animated:(BOOL)animated;
{
	NSUInteger index = [self.viewControllers indexOfObject:newSelectedViewController];
	if (index != NSNotFound)
		[self setSelectedIndex:index animated:animated];
}

- (void)tabButtonPressed:(UISegmentedControl *)sender {
	[self setSelectedIndex:sender.selectedSegmentIndex animated:YES];
}

@end
