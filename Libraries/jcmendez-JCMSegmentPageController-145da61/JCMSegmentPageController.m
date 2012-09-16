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

static const float TAB_BAR_HEIGHT = 44.0f;

@implementation JCMSegmentPageController {
	UIView *headerContainerView;
  UISegmentedControl *segmentedControl;
	UIView *contentContainerView;
}

@synthesize viewControllers = _viewControllers;
@synthesize selectedIndex = _selectedIndex;
@synthesize delegate = _delegate;

- (void)removeAllSegments {
  [segmentedControl removeAllSegments];
}

- (void)addSegments {
	NSUInteger index = 0;
	for (UIViewController *viewController in self.viewControllers) {
    [segmentedControl insertSegmentWithTitle:viewController.title atIndex:index animated:NO];
		++index;
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

- (void)layoutHeaderView {
	CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, TAB_BAR_HEIGHT);
  segmentedControl.frame = CGRectInset(rect, 5.0, 5.0);
}

/**
 * When the view loads, we set the header, and on it, the segmented control that will control
 * the page being displayed
 */
- (void)viewDidLoad {
	[super viewDidLoad];

	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, TAB_BAR_HEIGHT);
	headerContainerView = [[UIView alloc] initWithFrame:rect];
	headerContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  CGRect segmentedControlRect = CGRectInset(rect, 5.0, 5.0);
  segmentedControl = [[UISegmentedControl alloc] initWithFrame:segmentedControlRect];
  segmentedControl.momentary = NO;
  segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
  [segmentedControl addTarget:self action:@selector(tabButtonPressed:) forControlEvents:UIControlEventValueChanged];

  [headerContainerView addSubview:segmentedControl];
	[self.view addSubview:headerContainerView];

	rect.origin.y = TAB_BAR_HEIGHT;
	rect.size.height = self.view.bounds.size.height - TAB_BAR_HEIGHT;
	contentContainerView = [[UIView alloc] initWithFrame:rect];
	contentContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:contentContainerView];

	[self reloadTabButtons];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	headerContainerView = nil;
	contentContainerView = nil;
	segmentedControl = nil;
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	[self layoutHeaderView];
}

- (void)dealloc {
  _viewControllers = nil;
  _delegate = nil;
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
	NSAssert([newViewControllers count] >= 2, @"JCMSegmentPageController requires at least two view controllers");

	UIViewController *oldSelectedViewController = self.selectedViewController;

	// Remove the old child view controllers.
	for (UIViewController *viewController in _viewControllers) {
		[viewController willMoveToParentViewController:nil];
		[viewController removeFromParentViewController];
	}

	_viewControllers = [newViewControllers copy];

	// This follows the same rules as UITabBarController for trying to
	// re-select the previously selected view controller.
	NSUInteger newIndex = [_viewControllers indexOfObject:oldSelectedViewController];
	if (newIndex != NSNotFound)
		_selectedIndex = newIndex;
	else if (newIndex < [_viewControllers count])
		_selectedIndex = newIndex;
	else
		_selectedIndex = 0;

	// Add the new child view controllers.
	for (UIViewController *viewController in _viewControllers) {
		[self addChildViewController:viewController];
		[viewController didMoveToParentViewController:self];
	}

	if ([self isViewLoaded])
		[self reloadTabButtons];
}

- (void)setSelectedIndex:(NSUInteger)newSelectedIndex {
	[self setSelectedIndex:newSelectedIndex animated:NO];
}

- (void)setSelectedIndex:(NSUInteger)newSelectedIndex animated:(BOOL)animated {
	NSAssert(newSelectedIndex < [self.viewControllers count], @"View controller index out of bounds");

	if ([self.delegate respondsToSelector:@selector(segmentPageController:shouldSelectViewController:atIndex:)]) {
		UIViewController *toViewController = [self.viewControllers objectAtIndex:newSelectedIndex];
		if (![self.delegate segmentPageController:self shouldSelectViewController:toViewController atIndex:newSelectedIndex])
			return;
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
      [segmentedControl setSelectedSegmentIndex:_selectedIndex];
			toViewController = self.selectedViewController;
		}

		if (toViewController == nil) { // don't animate
			[fromViewController.view removeFromSuperview];
		}
		else if (fromViewController == nil) { // don't animate
			toViewController.view.frame = contentContainerView.bounds;
			[contentContainerView addSubview:toViewController.view];

			if ([self.delegate respondsToSelector:@selector(segmentPageController:didSelectViewController:atIndex:)])
				[self.delegate segmentPageController:self didSelectViewController:toViewController atIndex:newSelectedIndex];
		} else if (animated) {
			CGRect rect = contentContainerView.bounds;
			if (oldSelectedIndex < newSelectedIndex)
				rect.origin.x = rect.size.width;
			else
				rect.origin.x = -rect.size.width;

			toViewController.view.frame = rect;
			headerContainerView.userInteractionEnabled = NO;

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
					toViewController.view.frame = contentContainerView.bounds;
				}
				completion:^(BOOL finished) {
					headerContainerView.userInteractionEnabled = YES;

					if ([self.delegate respondsToSelector:@selector(segmentPageController:didSelectViewController:atIndex:)])
						[self.delegate segmentPageController:self didSelectViewController:toViewController atIndex:newSelectedIndex];
				}];
		} else { // not animated
			[fromViewController.view removeFromSuperview];

			toViewController.view.frame = contentContainerView.bounds;
			[contentContainerView addSubview:toViewController.view];

			if ([self.delegate respondsToSelector:@selector(segmentPageController:didSelectViewController:atIndex:)])
				[self.delegate segmentPageController:self didSelectViewController:toViewController atIndex:newSelectedIndex];
		}
	}
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
