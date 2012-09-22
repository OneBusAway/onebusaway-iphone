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

#import "OBAApplicationContext.h"
#import "OBANavigationTargetAware.h"
#import "OBAArrivalsAndDeparturesForStopV2.h"
#import "OBABookmarkV2.h"
#import "OBAProgressIndicatorView.h"
#import "OBAArrivalEntryTableViewCellFactory.h"
#import "OBAStopV2.h"

typedef enum {
	OBAStopSectionTypeNone,
	OBAStopSectionTypeName,
	OBAStopSectionTypeArrivals,
	OBAStopSectionTypeFilter,
	OBAStopSectionTypeServiceAlerts,
	OBAStopSectionTypeActions
} OBAStopSectionType;

@interface OBAGenericStopViewController : UITableViewController <OBANavigationTargetAware,UIActionSheetDelegate,OBAModelServiceDelegate>
@property(strong,readonly) OBAApplicationContext * appContext;
@property(strong,readonly) NSString * stopId;
@property BOOL showTitle;
@property BOOL showServiceAlerts;
@property BOOL showActions;
@property NSUInteger minutesBefore;
@property(strong) OBAArrivalEntryTableViewCellFactory * arrivalCellFactory;
@property(strong) NSMutableArray *allArrivals;
@property(strong) NSMutableArray *filteredArrivals;
@property BOOL showFilteredArrivals;

- (id)initWithApplicationContext:(OBAApplicationContext*)appContext;
- (id)initWithApplicationContext:(OBAApplicationContext*)appContext stopId:(NSString*)stopId;
- (id)initWithApplicationContext:(OBAApplicationContext *)appContext stop:(OBAStopV2*)stop;
- (OBAStopSectionType) sectionTypeForSection:(NSUInteger)section;
@end
