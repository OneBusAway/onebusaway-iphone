/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAUIKit.h"


@implementation OBAUIKit

+(void) addToolbar:(UIToolbar*)toolbar toParentView:(UIView*) parentView withMainView:(UIView*)view animated:(BOOL)animated {

	[toolbar sizeToFit];
	[parentView addSubview:toolbar];
	
	//Caclulate the height of the toolbar
	CGFloat toolbarHeight = [toolbar frame].size.height;
	
	//Get the bounds of the parent view
	CGRect rootViewBounds = parentView.bounds;
		
	//Get the height of the parent view.
	CGFloat rootViewHeight = CGRectGetHeight(rootViewBounds);
	
	//Get the width of the parent view,
	CGFloat rootViewWidth = CGRectGetWidth(rootViewBounds);
	
	//Create a rectangle for the toolbar
	CGRect rectArea = CGRectMake(0, rootViewHeight - toolbarHeight, rootViewWidth, toolbarHeight);
	
	CGRect mainViewFrame = [view frame];
	mainViewFrame.size.height -= toolbarHeight;

	if( animated ) {
		CGRect rectAreaPre = CGRectMake(0, rootViewHeight, rootViewWidth, toolbarHeight);	
		[toolbar setFrame:rectAreaPre];
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.4];
		[UIView setAnimationDelegate: self];		
	}

	//Reposition and resize the receiver
	[toolbar setFrame:rectArea];	
	[view setFrame:mainViewFrame];
	
	if( animated )
		[UIView commitAnimations];

}

@end

@implementation UINavigationController (OBAConvenienceMethods)

-(void) replaceViewController:(UIViewController*)viewController animated:(BOOL)animated {
	NSMutableArray * viewControllers = [NSMutableArray arrayWithArray:self.viewControllers];
	[viewControllers insertObject:viewController atIndex:[viewControllers count]-1];
	self.viewControllers = viewControllers;
	[self popViewControllerAnimated:animated]; 	
}
		
-(void) replaceViewControllerWithAnimation:(UIViewController*)viewController {
	[self replaceViewController:viewController animated:YES];
}
			
-(void) replaceViewControllerWithoutAnimation:(UIViewController*)viewController {
	[self replaceViewController:viewController animated:NO];	
}

-(void) pushViewController:(UIViewController*)controller animated:(BOOL)animated removeAnyExisting:(BOOL)removeAnyExisting {
	NSMutableArray * controllers = [[NSMutableArray alloc] initWithArray:self.viewControllers];
	for( UIViewController * vc in self.viewControllers ) {
		if( [vc isKindOfClass:[controller class]] )
			[controllers removeObject:vc];
	}
	[controllers addObject:controller];
	[self setViewControllers:controllers animated:animated];
}

-(void) popToRootViewController {
	[self popToRootViewControllerAnimated:NO];
}


@end



@implementation UITableViewCell (OBAConvenienceMethods)

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView cellId:(NSString*)cellId {
	
	// Try to retrieve from the table view a now-unused cell with the given identifier
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	
	// If no cell is available, create a new one using the given identifier
	if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
	}
	
	return cell;
}

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView {
	static NSString *cellId = @"DefaultIdentifier";
	return [self getOrCreateCellForTableView:tableView cellId:cellId];
}

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView style:(UITableViewCellStyle)style {    
	NSString * cellId = [NSString stringWithFormat:@"DefaultIdentifier-%d",style];
	return [self getOrCreateCellForTableView:tableView style:style cellId:cellId];
}

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView style:(UITableViewCellStyle)style cellId:(NSString*)cellId {

    // Try to retrieve from the table view a now-unused cell with the given identifier
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
	
	// If no cell is available, create a new one using the given identifier
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:cellId];
    
	return cell;
}

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView fromResource:(NSString*)resourceName {
	
	UITableViewCell * cell = (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:resourceName];
	
	if (cell == nil) {
		NSArray * nib = [[NSBundle mainBundle] loadNibNamed:resourceName owner:self options:nil];
		cell = nib[0];
	}
	
	return cell;
}

@end
