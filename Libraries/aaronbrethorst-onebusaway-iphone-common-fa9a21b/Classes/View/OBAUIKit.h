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

//#import <Foundation/Foundation.h>


@interface OBAUIKit : NSObject

+(void) addToolbar:(UIToolbar*)toolbar toParentView:(UIView*) parentView withMainView:(UIView*)view animated:(BOOL)animated;

@end

@interface UINavigationController (OBAConvenienceMethods)

-(void) replaceViewController:(UIViewController*)viewController animated:(BOOL)animated;
-(void) replaceViewControllerWithAnimation:(UIViewController*)viewController;
-(void) replaceViewControllerWithoutAnimation:(UIViewController*)viewController;
-(void) pushViewController:(UIViewController*)controller animated:(BOOL)animated removeAnyExisting:(BOOL)removeAnyExisting;
-(void) popToRootViewController;

@end

@interface UITableViewCell (OBAConvenienceMethods)

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView cellId:(NSString*)cellId;

+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView;
+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView style:(UITableViewCellStyle)style;
+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView style:(UITableViewCellStyle)style cellId:(NSString*)cellId;
+(UITableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView fromResource:(NSString*)resourceName;

@end
