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

@protocol JCMSegmentPageControllerDelegate;

/**
 * Custom container view controller for iOS5 that functions similarly to a 
 * UITabBarController, but the way to switch tabs is through a 
 * UISegmentedControl on top.
 */
@interface JCMSegmentPageController : UIViewController

/// Keeps an array of the controllers managed by this container controller
@property (nonatomic, copy) NSArray *viewControllers;
/// Reference to the currently selected controller
@property (nonatomic, weak) UIViewController *selectedViewController;
/// Index of the currently selected controller
@property (nonatomic, assign) NSUInteger selectedIndex;
/// Optional delegate that can be informed of a new selection and decide
/// whether a page can or can't be selected
@property (nonatomic, weak) id <JCMSegmentPageControllerDelegate> delegate;

- (void)setSelectedIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)setSelectedViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

/**
 * The delegate protocol for JCMSegmentPageController.
 */
@protocol JCMSegmentPageControllerDelegate <NSObject>
@optional
/**
 * Delegate can decide if the page should be selected or not.  Default implementation is YES.
 * @return NO if the page shouldn't be selected
 * @param segmentPageController the JCMSegmentPageController generating this call
 * @param viewController the view controller (page) to decide if should or shouldn't be selected
 * @param index the index of this page within the container
 */
- (BOOL)segmentPageController:(JCMSegmentPageController *)segmentPageController shouldSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
/**
 * Delegate gets notified after the page was selected.
 * @param segmentPageController the JCMSegmentPageController generating this call
 * @param viewController the view controller (page) that was selected
 * @param index the index of this page within the container
 */
- (void)segmentPageController:(JCMSegmentPageController *)segmentPageController didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index;
@end
