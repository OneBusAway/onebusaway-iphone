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
#import "OBANavigationTargetAware.h"
#import "OBAArrivalsAndDeparturesForStopV2.h"
#import "OBABookmarkV2.h"
#import "OBAProgressIndicatorView.h"
#import "OBAArrivalEntryTableViewCellFactory.h"

typedef NS_ENUM(NSInteger, OBAStopSectionType) {
    OBAStopSectionTypeNone,
    OBAStopSectionTypeArrivals,
    OBAStopSectionTypeFilter,
    OBAStopSectionTypeServiceAlerts,
    OBAStopSectionTypeActions
};

NS_ASSUME_NONNULL_BEGIN

@interface OBAGenericStopViewController : UITableViewController <OBANavigationTargetAware>

@property(strong,readonly) OBAApplicationDelegate * appDelegate;
@property(strong,readonly) NSString * stopId;
@property BOOL showTitle;
@property BOOL showServiceAlerts;
@property BOOL showActions;
@property NSUInteger minutesBefore;
@property NSUInteger minutesAfter;
@property(strong) OBAArrivalEntryTableViewCellFactory * arrivalCellFactory;
@property(strong) NSMutableArray *allArrivals;
@property(strong) NSMutableArray *filteredArrivals;
@property BOOL showFilteredArrivals;

- (id)initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate stopId:(NSString*)stopId;
- (OBAStopSectionType) sectionTypeForSection:(NSUInteger)section;
- (void)refresh;
@end

NS_ASSUME_NONNULL_END
