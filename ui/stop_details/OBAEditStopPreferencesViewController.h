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

#import "OBAApplicationDelegate.h"
#import "OBAStopV2.h"
#import "OBAStopPreferencesV2.h"

@interface OBAEditStopPreferencesViewController : UITableViewController {
    OBAApplicationDelegate * _appDelegate;
    OBAStopV2 * _stop;
    NSArray * _routes;
    OBAStopPreferencesV2 * _preferences;
}

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate stop:(OBAStopV2*)stop;

- (IBAction) onCancelButton:(id)sender;
- (IBAction) onSaveButton:(id)sender;

- (UITableViewCell *)tableView:(UITableView *)tableView sortByCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView routeCellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
