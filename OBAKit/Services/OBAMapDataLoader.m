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

#import <OBAKit/OBAMapDataLoader.h>
#import <OBAKit/OBAKit-Swift.h>

@interface OBAMapDataLoader ()
@property (nonatomic, strong, readwrite) OBASearchResult *result;
@property (nonatomic, strong) OBANavigationTarget *target;
@property (nonatomic, strong) CLLocation *lastCurrentLocationSearch;
@property (nonatomic, strong) NSHashTable *delegates;
@end

@implementation OBAMapDataLoader

- (instancetype)init {
    if (self = [super init]) {
        _searchType = OBASearchTypeNone;
        _delegates = [NSHashTable weakObjectsHashTable];
    }

    return self;
}

- (void)dealloc {
    [self cancelOpenConnections];
}

#pragma mark - Delegates

- (void)addDelegate:(id<OBAMapDataLoaderDelegate>)delegate {
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<OBAMapDataLoaderDelegate>)delegate {
    [self.delegates removeObject:delegate];
}

- (void)callDelegatesDidUpdateResult:(OBASearchResult*)searchResult {
    for (id<OBAMapDataLoaderDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(mapDataLoader:didUpdateResult:)]) {
            [delegate mapDataLoader:self didUpdateResult:searchResult];
        }
    }
}

- (void)callDelegatesStartedUpdatingWithNavigationTarget:(OBANavigationTarget*)target {
    for (id<OBAMapDataLoaderDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(mapDataLoader:startedUpdatingWithNavigationTarget:)]) {
            [delegate mapDataLoader:self startedUpdatingWithNavigationTarget:target];
        }
    }
}

- (void)callDelegatesFinishedUpdating {
    for (id<OBAMapDataLoaderDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(mapDataLoaderFinishedUpdating:)]) {
            [delegate mapDataLoaderFinishedUpdating:self];
        }
    }
}

- (void)callDelegatesDidReceiveError:(NSError*)error {
    for (id<OBAMapDataLoaderDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(mapDataLoader:didReceiveError:)]) {
            [delegate mapDataLoader:self didReceiveError:error];
        }
    }
}

#pragma mark - Public Methods

- (void)searchWithTarget:(OBANavigationTarget *)target {
    [self cancelOpenConnections];

    _target = target;
    _searchType = target.searchType;

    // Short circuit if the request is NONE
    if (_searchType == OBASearchTypeNone) {
        OBASearchResult *result = [OBASearchResult result];
        result.searchType = OBASearchTypeNone;
        [self fireUpdate:result];
        [self callDelegatesFinishedUpdating];
        return;
    }

    [self requestTarget:target];
    [self callDelegatesStartedUpdatingWithNavigationTarget:target];
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

        case OBASearchTypeStopIdSearch: {
            promise = [self requestStopIDWithStopCode:searchTypeParameter];
            break;
        }

        default:
            break;
    }

    promise.catch(^(NSError *error) {
        [self processError:error responseCode:error.code];
    }).always(^{
        [self callDelegatesFinishedUpdating];
    });

    return promise;
}

#pragma mark - Update Data

- (void)fireUpdate:(OBASearchResult *)result {
    result.searchType = self.searchType;
    self.result = result;
    [self callDelegatesDidUpdateResult:self.result];
}

- (void)processError:(NSError *)error responseCode:(NSUInteger)responseCode {
    if (responseCode == 0 && error.code == NSURLErrorCancelled) {
        // This shouldn't be happening, and frankly I'm not entirely sure why it's happening.
        // But, I do know that it doesn't have any appreciable user impact outside of this
        // error alert being really annoying. So we'll just log it and eat it.

        DDLogError(@"Errored out at launch: %@", error);
    }
    else if (error) {
        [self callDelegatesFinishedUpdating];
        self.error = error;
        [self callDelegatesDidReceiveError:error];
    }
    else {
        [self callDelegatesFinishedUpdating];
    }
}

@end
