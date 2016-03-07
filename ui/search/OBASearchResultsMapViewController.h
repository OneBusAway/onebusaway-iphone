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

#import "OBANavigationTargetAware.h"
#import "OBASearchController.h"
#import "OBAGenericAnnotation.h"
#import "OBAMapRegionManager.h"
#import "OBAScopeView.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBASearchResultsMapViewController : UIViewController <OBANavigationTargetAware, OBASearchControllerDelegate, MKMapViewDelegate,OBALocationManagerDelegate,OBAProgressIndicatorDelegate, UISearchBarDelegate>
@property(nonatomic,strong) OBAApplicationDelegate * appDelegate;
@property(nonatomic,strong) IBOutlet OBAScopeView *scopeView;
@property(nonatomic,strong) IBOutlet UISegmentedControl *searchTypeSegmentedControl;
@property(nonatomic,strong) IBOutlet MKMapView * mapView;
@property(nonatomic,strong) IBOutlet UISearchBar *searchBar;
@property(nonatomic,strong) IBOutlet UIToolbar *toolbar;
@property(nonatomic,strong) IBOutlet UILabel *mapLabel;

- (IBAction)onCrossHairsButton:(id)sender;
- (IBAction)showListView:(id)sender;

@end

NS_ASSUME_NONNULL_END