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

#import <UIKit/UIKit.h>
#import <OBAKit/OBAKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBASituationsViewController : UITableViewController {
    NSArray<OBASituationV2*> * _situations;
}
@property (nonatomic,strong,nullable) NSDictionary * args;

+ (void)showSituations:(NSArray<OBASituationV2*>*)situations navigationController:(UINavigationController*)navController args:(nullable NSDictionary*)args;
- (instancetype)initWithSituations:(NSArray<OBASituationV2*>*)situations;
@end

NS_ASSUME_NONNULL_END
