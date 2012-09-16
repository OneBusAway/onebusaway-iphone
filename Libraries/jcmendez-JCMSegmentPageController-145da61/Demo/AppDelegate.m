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

#import "AppDelegate.h"
#import "DemoSimpleTableViewController.h"

@implementation AppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	DemoSimpleTableViewController *listViewController1 = [[DemoSimpleTableViewController alloc] initWithStyle:UITableViewStylePlain];
	DemoSimpleTableViewController *listViewController2 = [[DemoSimpleTableViewController alloc] initWithStyle:UITableViewStylePlain];
	DemoSimpleTableViewController *listViewController3 = [[DemoSimpleTableViewController alloc] initWithStyle:UITableViewStylePlain];
	
	listViewController1.title = @"One";
	listViewController2.title = @"Two";
	listViewController3.title = @"Three";

	NSArray *viewControllers = [NSArray arrayWithObjects:listViewController1, listViewController2, listViewController3, nil];
	JCMSegmentPageController *segmentPageController = [[JCMSegmentPageController alloc] init];

	segmentPageController.delegate = self;
	segmentPageController.viewControllers = viewControllers;

	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = segmentPageController;
	[self.window makeKeyAndVisible];
	return YES;
}

- (BOOL)segmentPageController:(JCMSegmentPageController *)segmentPageController shouldSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index {
	NSLog(@"segmentPageController %@ shouldSelectViewController %@ at index %u", segmentPageController, viewController, index);
	return YES;
}

- (void)segmentPageController:(JCMSegmentPageController *)segmentPageController didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index {
	NSLog(@"segmentPageController %@ didSelectViewController %@ at index %u", segmentPageController, viewController, index);
}

@end
