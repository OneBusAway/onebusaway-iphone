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

#import "OBASearch.h"
#import "OBASearchResult.h"
#import "OBAApplicationDelegate.h"
#import "OBAProgressIndicatorSource.h"
#import "OBAPlacemark.h"
#import "OBADataSource.h"
#import "OBAModelService.h"


#pragma mark OBASearchControllerDelegate Protocol

@protocol OBASearchControllerDelegate <NSObject>

- (void) handleSearchControllerUpdate:(OBASearchResult*)result;

@optional

- (void) handleSearchControllerStarted:(OBASearchType)searchType;
- (void) handleSearchControllerError:(NSError*)error;

@end


#pragma mark OBASearchController

@class OBAProgressIndicatorImpl;

@interface OBASearchController : NSObject <OBAModelServiceDelegate> {
    
    OBAModelService * _modelService;
    
    OBANavigationTarget * _target;
    id<OBAModelServiceRequest> _request;

    CLLocation * _lastCurrentLocationSearch;    
}

@property (nonatomic,weak) id<OBASearchControllerDelegate> delegate;
@property (nonatomic,readonly) OBASearchType searchType;
@property (weak, nonatomic,readonly) id searchParameter;
@property (strong,readonly) OBASearchResult * result;

@property (weak, nonatomic,readonly) CLLocation * searchLocation;
@property (nonatomic,strong) CLRegion *searchRegion;

@property (nonatomic,strong) NSObject<OBAProgressIndicatorSource>* progress;
@property (nonatomic,strong) NSError * error;


- (id) initWithappDelegate:(OBAApplicationDelegate*)context;
- (BOOL)unfilteredSearch;
-(void) searchWithTarget:(OBANavigationTarget*)target;
-(void) searchPending;
-(OBANavigationTarget*) getSearchTarget;
-(void) cancelOpenConnections;


@end
