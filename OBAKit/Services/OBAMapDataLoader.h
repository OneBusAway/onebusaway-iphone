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

@import Foundation;
@import CoreLocation;

#import <OBAKit/OBASearchResult.h>
#import <OBAKit/OBANavigationTarget.h>

@class PromisedModelService;

NS_ASSUME_NONNULL_BEGIN

@class OBAMapDataLoader;
@protocol OBAMapDataLoaderDelegate <NSObject>
@optional
- (void)mapDataLoader:(OBAMapDataLoader*)mapDataLoader didUpdateResult:(OBASearchResult*)searchResult;
- (void)mapDataLoader:(OBAMapDataLoader*)mapDataLoader startedUpdatingWithNavigationTarget:(OBANavigationTarget*)target;
- (void)mapDataLoaderFinishedUpdating:(OBAMapDataLoader*)mapDataLoader;
- (void)mapDataLoader:(OBAMapDataLoader*)mapDataLoader didReceiveError:(NSError*)error;
@end

@interface OBAMapDataLoader : NSObject
@property(nonatomic,strong) PromisedModelService *modelService;

- (void)addDelegate:(id<OBAMapDataLoaderDelegate>)delegate;
- (void)removeDelegate:(id<OBAMapDataLoaderDelegate>)delegate;

@property(nonatomic,strong,readonly) OBANavigationTarget *searchTarget;
@property(nonatomic,readonly) OBASearchType searchType;
@property(weak, nonatomic,readonly) id searchParameter;
@property(strong,readonly,nullable) OBASearchResult * result;

@property(nonatomic,copy,nullable,readonly) CLLocation * searchLocation;
@property(nonatomic,copy) CLCircularRegion *searchRegion;
@property(nonatomic,copy) NSError * error;

- (instancetype)initWithModelService:(PromisedModelService*)modelService;

- (BOOL)unfilteredSearch;
- (void)searchWithTarget:(OBANavigationTarget*)target;
- (void)searchPending;
- (void)cancelOpenConnections;

@end

NS_ASSUME_NONNULL_END
