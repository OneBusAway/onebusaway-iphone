/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OBAListSelectionViewControllerDelegate <NSObject>
- (void) checkItemWithIndex:(NSIndexPath*)indexPath;
@end

@interface OBAListSelectionViewController : UITableViewController 

@property (nonatomic,strong) NSIndexPath *checkedItem;
@property (nonatomic) id<OBAListSelectionViewControllerDelegate> delegate;
@property (nonatomic) BOOL exitOnSelection;

- (id)initWithValues:(NSArray*)values selectedIndex:(NSIndexPath*)selectedIndex;

@end

NS_ASSUME_NONNULL_END
