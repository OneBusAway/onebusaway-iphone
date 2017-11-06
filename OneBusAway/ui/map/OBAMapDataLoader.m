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

#import "OBAMapDataLoader.h"

@interface OBAMapDataLoader ()
@property (nonatomic, strong, readwrite) OBASearchResult *result;
@property (nonatomic, strong) OBANavigationTarget *target;
@property (nonatomic, strong) CLLocation *lastCurrentLocationSearch;
@end

@implementation OBAMapDataLoader

- (instancetype)initWithModelService:(PromisedModelService*)modelService {
    if (self = [super init]) {
        _modelService = modelService;
        _searchType = OBASearchTypeNone;
    }

    return self;
}

- (void)dealloc {
    [self cancelOpenConnections];
}

#pragma mark - Accessors

- (PromisedModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - Public Methods

- (void)searchWithTarget:(OBANavigationTarget *)target {
    id<OBAMapDataLoaderDelegate> delegate = self.delegate;
    [self cancelOpenConnections];

    _target = target;
    _searchType = target.searchType;

    // Short circuit if the request is NONE
    if (_searchType == OBASearchTypeNone) {
        OBASearchResult *result = [OBASearchResult result];
        result.searchType = OBASearchTypeNone;
        [self fireUpdate:result];
        [delegate mapDataLoaderFinishedUpdating:self];
        return;
    }

    [self requestTarget:target];
    [delegate mapDataLoader:self startedUpdatingWithNavigationTarget:target];
}

- (void)searchPending {
    [self cancelOpenConnections];
    _target = nil;
    _searchType = OBASearchTypePending;
}

- (OBANavigationTarget*)searchTarget {
    return _target;
}

- (id)searchParameter {
    return _target.searchArgument;
}

- (CLLocation *)searchLocation {
    return _target.parameters[kOBASearchControllerSearchLocationParameter];
}

- (void)setSearchLocation:(CLLocation *)location {
    if (!location) {
        return;
    }

    [_target setObject:location forParameter:kOBASearchControllerSearchLocationParameter];
}

- (void)cancelOpenConnections {
    _searchType = OBASearchTypeNone;
    self.result = nil;
}

#pragma mark - Public Methods

- (BOOL)unfilteredSearch {
    return (  self.searchType == OBASearchTypeNone
           || self.searchType == OBASearchTypePending
           || self.searchType == OBASearchTypeRegion
           || self.searchType == OBASearchTypePlacemark);
}

#pragma mark - Data Requests

- (AnyPromise*)requestRegion:(MKCoordinateRegion)region {
    return [self.modelService requestStopsForRegion:region].then(^(OBASearchResult *result) {
        [self fireUpdate:result];
    });
}

- (AnyPromise*)requestRouteWithQuery:(NSString*)routeQuery {
    OBAGuardClass(routeQuery, NSString) else {
        return nil;
    }
    return [self.modelService requestRoutesForQuery:routeQuery region:self.searchRegion].then(^(OBASearchResult *result) {
        [self fireUpdate:result];
    });
}

- (AnyPromise*)requestStopsForRouteID:(NSString*)routeID {
    return [self.modelService requestStopsForRoute:routeID].then(^(OBAStopsForRouteV2* stopsForRoute) {
        OBASearchResult *result = [OBASearchResult result];
        result.values = [stopsForRoute stops];
        result.additionalValues = stopsForRoute.polylines;
        [self fireUpdate:result];
    });
}

- (AnyPromise*)requestAddressWithQuery:(NSString*)addressQuery {
    return [self.modelService placemarksForAddress:addressQuery].then(^(NSArray<OBAPlacemark*>* placemarks) {
        if (placemarks.count == 1) {
            OBAPlacemark *placemark = placemarks[0];
            OBANavigationTarget *navTarget = [OBANavigationTarget navigationTargetForSearchPlacemark:placemark];
            [self searchWithTarget:navTarget];
        }
        else {
            OBASearchResult *result = [OBASearchResult result];
            result.values = placemarks;
            [self fireUpdate:result];
        }
    });
}

- (AnyPromise*)requestPlacemark:(OBAPlacemark*)placemark {
    return [self.modelService requestStopsForPlacemark:placemark].then(^(OBASearchResult* result) {
        OBAPlacemark *newMark = self.target.parameters[OBANavigationTargetSearchKey];
        result.additionalValues = @[newMark];
        [self fireUpdate:result];
    });
}

- (AnyPromise*)requestStopIDWithStopCode:(NSString*)stopCode {
    return [self.modelService requestStopsForQuery:stopCode region:self.searchRegion].then(^(OBASearchResult* result) {
        [self fireUpdate:result];
    });
}

- (AnyPromise*)requestTarget:(OBANavigationTarget *)target {
    id searchTypeParameter = target.searchArgument;
    AnyPromise *promise = nil;

    OBASearchType searchType = target.searchType;

    switch (searchType) {
        case OBASearchTypeRegion: {
            MKCoordinateRegion region;
            [searchTypeParameter getBytes:&region length:sizeof(MKCoordinateRegion)];
            promise = [self requestRegion:region];
            break;
        }

        case OBASearchTypeRoute: {
            promise = [self requestRouteWithQuery:searchTypeParameter];
            break;
        }

        case OBASearchTypeStops: {
            promise = [self requestStopsForRouteID:searchTypeParameter];
            break;
        }

        case OBASearchTypeAddress: {
            promise = [self requestAddressWithQuery:searchTypeParameter];
            break;
        }

        case OBASearchTypePlacemark: {
            promise = [self requestPlacemark:searchTypeParameter];
            break;
        }

        case OBASearchTypeStopId: {
            promise = [self requestStopIDWithStopCode:searchTypeParameter];
            break;
        }

        default:
            break;
    }

    promise.catch(^(NSError *error) {
        [self processError:error responseCode:error.code];
    }).always(^{
        [self.delegate mapDataLoaderFinishedUpdating:self];
    });

    return promise;
}

#pragma mark - Update Data

- (void)fireUpdate:(OBASearchResult *)result {
    result.searchType = self.searchType;
    self.result = result;
    [self.delegate mapDataLoader:self didUpdateResult:self.result];
}

- (void)processError:(NSError *)error responseCode:(NSUInteger)responseCode {
    id<OBAMapDataLoaderDelegate> delegate = self.delegate;

    if (responseCode == 0 && error.code == NSURLErrorCancelled) {
        // This shouldn't be happening, and frankly I'm not entirely sure why it's happening.
        // But, I do know that it doesn't have any appreciable user impact outside of this
        // error alert being really annoying. So we'll just log it and eat it.

        DDLogError(@"Errored out at launch: %@", error);
    }
    else if (error) {
        [delegate mapDataLoaderFinishedUpdating:self];
        self.error = error;
        [delegate mapDataLoader:self didReceiveError:error];
    }
    else {
        [delegate mapDataLoaderFinishedUpdating:self];
    }
}

@end
