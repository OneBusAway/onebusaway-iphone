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
#import "OBAApplicationDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class OBASearchController;
@protocol OBASearchControllerDelegate <NSObject>
- (void)handleSearchControllerUpdate:(OBASearchResult*)result;
- (void)searchControllerBeganUpdating:(OBASearchController*)searchController;
- (void)searchControllerFinishedUpdating:(OBASearchController*)searchController;
- (void)handleSearchControllerStarted:(OBASearchType)searchType;
- (void)handleSearchControllerError:(NSError*)error;
@end

@interface OBASearchController : NSObject
@property(nonatomic,strong) OBAModelService *modelService;

@property(nonatomic,weak) id<OBASearchControllerDelegate> delegate;
@property(nonatomic,strong,readonly) OBANavigationTarget *searchTarget;
@property(nonatomic,readonly) OBASearchType searchType;
@property(weak, nonatomic,readonly) id searchParameter;
@property(strong,readonly,nullable) OBASearchResult * result;

@property(weak, nonatomic,readonly) CLLocation * searchLocation;
@property(nonatomic,strong) CLCircularRegion *searchRegion;
@property(nonatomic,strong) NSError * error;

- (instancetype)initWithModelService:(OBAModelService*)modelService;

- (BOOL)unfilteredSearch;
- (void)searchWithTarget:(OBANavigationTarget*)target;
- (void)searchPending;
- (void)cancelOpenConnections;

@end

NS_ASSUME_NONNULL_END
