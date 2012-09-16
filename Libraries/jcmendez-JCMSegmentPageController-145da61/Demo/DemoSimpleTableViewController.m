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

#import "DemoSimpleTableViewController.h"
#import "JCMSegmentPageController.h"

@implementation DemoSimpleTableViewController

- (void)dealloc {
	NSLog(@"dealloc %@", self);
}

- (void)viewDidLoad {
	[super viewDidLoad];
	NSLog(@"%@ viewDidLoad", self.title);
}

- (void)viewDidUnload {
	[super viewDidUnload];
	NSLog(@"%@ viewDidUnload", self.title);
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	NSLog(@"%@ viewWillAppear", self.title);
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	NSLog(@"%@ viewDidAppear", self.title);
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	NSLog(@"%@ viewWillDisappear", self.title);
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	NSLog(@"%@ viewDidDisappear", self.title);
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
	[super willMoveToParentViewController:parent];
	NSLog(@"%@ willMoveToParentViewController %@", self.title, parent);
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
	[super didMoveToParentViewController:parent];
	NSLog(@"%@ didMoveToParentViewController %@", self.title, parent);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	NSLog(@"%@ willRotateToInterfaceOrientation", self.title);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	cell.textLabel.text = [NSString stringWithFormat:@"Page %@ - Row %d", self.title, indexPath.row];
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"%@, parent is %@", self.title, self.parentViewController);

	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	DemoSimpleTableViewController *listViewController1 = [[DemoSimpleTableViewController alloc] initWithStyle:UITableViewStylePlain];
	DemoSimpleTableViewController *listViewController2 = [[DemoSimpleTableViewController alloc] initWithStyle:UITableViewStylePlain];
	
  NSString *myName = ((JCMSegmentPageController *) self.parentViewController).selectedViewController.title;
  
	listViewController1.title = [NSString stringWithFormat: @"%@ sub 1", myName];
	listViewController2.title = [NSString stringWithFormat: @"%@ sub 2", myName];

	NSArray *viewControllers = [NSArray arrayWithObjects:listViewController1, listViewController2, nil];
	JCMSegmentPageController *segmentPageController = [[JCMSegmentPageController alloc] init];
	segmentPageController.viewControllers = viewControllers;
	segmentPageController.title = @"Modal dialog";
	segmentPageController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] 
		initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissModalScreen:)];

	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:segmentPageController];
	navController.navigationBar.tintColor = [UIColor colorWithRed:70/255.0f green:80/255.0f blue:90/255.0f alpha:1.0f];
	[self presentViewController:navController animated:YES completion:nil];
}

- (IBAction)dismissModalScreen:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
