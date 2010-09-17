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
#import "OBAApplicationContext.h"
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
	
	OBAProgressIndicatorImpl * _progress;
	
	id<OBASearchControllerDelegate> _delegate;
	
	OBANavigationTarget * _target;
	OBASearchType _searchType;
	id<OBAModelServiceRequest> _request;
	OBASearchResult * _result;
	NSError * _error;

	CLLocation * _lastCurrentLocationSearch;	
}

@property (nonatomic,assign) id<OBASearchControllerDelegate> delegate;
@property (nonatomic,readonly) OBASearchType searchType;
@property (nonatomic,readonly) id searchParameter;
@property (nonatomic,readonly) OBASearchResult * result;

@property (nonatomic,readonly) CLLocation * searchLocation;

@property (nonatomic,retain) NSObject<OBAProgressIndicatorSource>* progress;
@property (nonatomic,retain) NSError * error;


- (id) initWithAppContext:(OBAApplicationContext*)context;

-(void) searchWithTarget:(OBANavigationTarget*)target;
-(void) searchPending;
-(OBANavigationTarget*) getSearchTarget;
-(void) cancelOpenConnections;


@end
