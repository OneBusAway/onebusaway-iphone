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

@import OBAKit;
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

@class OBAModelDAO;

@class OBAMapViewController;

NS_SWIFT_NAME(MapControllerDelegate)
@protocol OBAMapControllerDelegate
- (void)mapController:(OBAMapViewController*)controller displayStopWithID:(NSString*)stopID;
- (void)mapController:(OBAMapViewController*)controller deselectedAnnotation:(id<MKAnnotation>)annotation;
@end

@interface OBAMapViewController : UIViewController <OBANavigationTargetAware, OBAMapDataLoaderDelegate>
INIT_NIB_UNAVAILABLE;
INIT_CODER_UNAVAILABLE;

@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) PromisedModelService *modelService;
@property(nonatomic,strong) OBALocationManager *locationManager;
@property(nonatomic,weak) id<OBAMapControllerDelegate> delegate;

/**
 When the view controller is in standalone mode, it will display toolbars. Defaults to true.
 Set it to false when hosting this view controller inside of another.
 */
@property(nonatomic,assign) BOOL standaloneMode;

@property(nonatomic,strong,readonly) CLCircularRegion *visibleMapRegion;

- (instancetype)initWithMapDataLoader:(OBAMapDataLoader*)mapDataLoader mapRegionManager:(OBAMapRegionManager*)mapRegionManager NS_DESIGNATED_INITIALIZER;

- (void)recenterMap;

- (void)deselectSelectedAnnotationView;
@end

NS_ASSUME_NONNULL_END
