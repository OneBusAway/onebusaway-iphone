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

#import "OBASearchController.h"
#import "OBAProgressIndicatorImpl.h"

NSString * const OBASearchControllerDidUpdateNotification = @"OBASearchControllerDidUpdateNotification";
NSString * const OBASearchControllerUserInfoDataKey = @"OBASearchControllerUserInfoDataKey";

@interface OBASearchController ()

@property (nonatomic, strong, readwrite) OBASearchResult *result;

@property (nonatomic, strong) OBAModelService *modelService;

@property (nonatomic, strong) OBANavigationTarget *target;
@property (nonatomic, strong) id<OBAModelServiceRequest> request;

@property (nonatomic, strong) CLLocation *lastCurrentLocationSearch;

@end

#pragma mark OBASearchController

@implementation OBASearchController

- (instancetype)initWithModelService:(OBAModelService*)modelService {
    if (self = [super init]) {
        _modelService = modelService;
        _searchType = OBASearchTypeNone;
        _progress = [[OBAProgressIndicatorImpl alloc] init];
    }

    return self;
}

- (void)dealloc {
    [self cancelOpenConnections];
}

- (void)searchWithTarget:(OBANavigationTarget *)target {
    [self cancelOpenConnections];

    _target = target;
    _searchType = [OBASearch getSearchTypeForNavigationTarget:target];

    // Short circuit if the request is NONE
    if (_searchType == OBASearchTypeNone) {
        OBASearchResult *result = [OBASearchResult result];
        result.searchType = OBASearchTypeNone;
        [self fireUpdate:result];
        [_progress setMessage:@"" inProgress:NO progress:0];
        return;
    }

    _request = [self requestForTarget:target];
    [_progress setMessage:NSLocalizedString(@"Connecting...", @"searchWithTarget _progress") inProgress:YES progress:0];
}

- (void)searchPending {
    [self cancelOpenConnections];
    _target = nil;
    _searchType = OBASearchTypePending;
}

- (OBANavigationTarget *)getSearchTarget {
    return _target;
}

- (id)searchParameter {
    return [OBASearch getSearchTypeParameterForNavigationTarget:_target];
}

- (CLLocation *)searchLocation {
    return [_target parameterForKey:kOBASearchControllerSearchLocationParameter];
}

- (void)setSearchLocation:(CLLocation *)location {
    if (location) [_target setParameter:location forKey:kOBASearchControllerSearchLocationParameter];
}

- (void)cancelOpenConnections {
    [_request cancel];
    _request = nil;

    _searchType = OBASearchTypeNone;
    self.result = nil;
}

#pragma mark - Public Methods

- (BOOL)unfilteredSearch {
    return (self.searchType == OBASearchTypeNone || self.searchType == OBASearchTypePending || self.searchType == OBASearchTypeRegion || self.searchType == OBASearchTypePlacemark);
}

#pragma mark OBAModelServiceDelegate

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
    [_progress setInProgress:YES progress:progress];
}

- (void)processError:(NSError *)error responseCode:(NSUInteger)responseCode {

    if (responseCode == 0 && error.code == NSURLErrorCancelled) {
        // This shouldn't be happening, and frankly I'm not entirely sure why it's happening.
        // But, I do know that it doesn't have any appreciable user impact outside of this
        // error alert being really annoying. So we'll just log it and eat it.

        DDLogError(@"Errored out at launch: %@", error);
    }
    else if (error) {
        [self.progress setMessage:NSLocalizedString(@"Error connecting", @"requestDidFail") inProgress:NO progress:0];
        [self fireError:error];
    }
    else if (responseCode == 404) {
        [self.progress setMessage:NSLocalizedString(@"Not found", @"code == 404") inProgress:NO progress:0];
    }
    else {
        [self.progress setMessage:NSLocalizedString(@"Server error", @"code # 404") inProgress:NO progress:0];
    }
}

- (void)processCompletion {
    NSString *message = [self progressCompleteMessageForSearchType];

    [self.progress setMessage:message inProgress:NO progress:0];
}

- (id<OBAModelServiceRequest>)requestForTarget:(OBANavigationTarget *)target {
    // Update our target parameters
    OBASearchType type = [OBASearch getSearchTypeForNavigationTarget:target];

    void (^ WrapperCompletion)() = ^(id responseData, NSUInteger responseCode, NSError *err, void (^complete)(id responseData)) {
        if (err || responseCode >= 300) {
            [self processError:err responseCode:responseCode];
        }
        else if (complete) {
            complete(responseData);
        }

        [self processCompletion];
    };

    switch (type) {
        case OBASearchTypeRegion: {
            NSData *data = [OBASearch getSearchTypeParameterForNavigationTarget:target];
            MKCoordinateRegion region;
            [data getBytes:&region length:sizeof(MKCoordinateRegion)];

            return [_modelService requestStopsForRegion:region completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
                WrapperCompletion(jsonData, responseCode, error, ^(id blockData) {
                    [self fireUpdateFromList:jsonData];
                });
            }];
        }

        case OBASearchTypeRoute: {
            NSString *routeQuery = [OBASearch getSearchTypeParameterForNavigationTarget:target];
            return [_modelService requestRoutesForQuery:routeQuery withRegion:self.searchRegion completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
                WrapperCompletion(jsonData, responseCode, error, ^(id data) {
                    OBAListWithRangeAndReferencesV2 *list = data;

                    if ([list count] == 1) {
                        OBARouteV2 *route = (list.values)[0];
                        OBANavigationTarget *navTarget = [OBASearch getNavigationTargetForSearchRouteStops:route.routeId];
                        [self performSelector:@selector(searchWithTarget:)
                                   withObject:navTarget
                                   afterDelay:0];
                    }
                    else {
                        [self fireUpdateFromList:list];
                    }
                });
            }];
        }

        case OBASearchTypeRouteStops: {
            NSString *routeId = [OBASearch getSearchTypeParameterForNavigationTarget:target];
            return [_modelService requestStopsForRoute:routeId completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
                WrapperCompletion(jsonData, responseCode, error, ^(id data) {
                    OBAStopsForRouteV2 *stopsForRoute = data;
                    OBASearchResult *result = [OBASearchResult result];
                    result.values = [stopsForRoute stops];
                    result.additionalValues = stopsForRoute.polylines;
                    [self fireUpdate:result];
                });
            }];
        }

        case OBASearchTypeAddress: {
            NSString *addressQuery = [OBASearch getSearchTypeParameterForNavigationTarget:target];
            return [_modelService placemarksForAddress:addressQuery completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
                WrapperCompletion(jsonData, responseCode, error, ^(id data) {
                    NSArray *placemarks = [data placemarks];

                    if ([placemarks count] == 1) {
                        OBAPlacemark *placemark = placemarks[0];
                        OBANavigationTarget *navTarget = [OBASearch getNavigationTargetForSearchPlacemark:placemark];
                        [self performSelector:@selector(searchWithTarget:)
                                   withObject:navTarget
                                   afterDelay:0];
                    }
                    else {
                        OBASearchResult *result = [OBASearchResult result];
                        result.values = placemarks;
                        [self fireUpdate:result];
                    }
                });
            }];
        }

        case OBASearchTypePlacemark: {
            OBAPlacemark *placemark = [OBASearch getSearchTypeParameterForNavigationTarget:target];
            return [_modelService requestStopsForPlacemark:placemark completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
                WrapperCompletion(jsonData, responseCode, error, ^(id data) {
                    OBASearchResult *result = [OBASearchResult resultFromList:data];
                    OBAPlacemark *newMark = [self.target parameterForKey:kOBASearchControllerSearchArgumentParameter];
                    result.additionalValues = @[newMark];
                    [self fireUpdate:result];
                });
            }];
        }

        case OBASearchTypeStopId: {
            NSString *stopCode = [OBASearch getSearchTypeParameterForNavigationTarget:target];
            return [_modelService requestStopsForQuery:stopCode withRegion:self.searchRegion completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
                WrapperCompletion(jsonData, responseCode, error, ^(id data) {
                    [self fireUpdateFromList:data];
                });
            }];
        }

        case OBASearchTypeAgenciesWithCoverage:
            return [_modelService requestAgenciesWithCoverage:^(id jsonData, NSUInteger responseCode, NSError *error) {
                WrapperCompletion(jsonData, responseCode, error, ^(id data) {
                    [self fireUpdateFromList:data];
                });
            }];

        default:
            break;
    }

    return nil;
}

- (NSString *)progressCompleteMessageForSearchType {
    NSString *title = nil;

    switch (_searchType) {
        case OBASearchTypeNone:
            title = @"";
            break;

        case OBASearchTypeRegion:
        case OBASearchTypePlacemark:
        case OBASearchTypeStopId:
        case OBASearchTypeRouteStops:
            title = NSLocalizedString(@"Stops", @"OBASearchTypeRouteStops");
            break;

        case OBASearchTypeRoute:
            title = NSLocalizedString(@"Routes", @"OBASearchTypeRoute");
            break;

        case OBASearchTypeAddress:
            title = NSLocalizedString(@"Places", @"OBASearchTypeAddress");
            break;

        case OBASearchTypeAgenciesWithCoverage:
            title = NSLocalizedString(@"Agencies", @"OBASearchTypeAgenciesWithCoverage");
            break;

        default:
            break;
    }

    return title;
}

- (void)fireUpdateFromList:(OBAListWithRangeAndReferencesV2 *)list {
    OBASearchResult *result = [OBASearchResult resultFromList:list];

    [self fireUpdate:result];
}

- (void)fireUpdate:(OBASearchResult *)result {
    result.searchType = _searchType;
    self.result = result;

    NSDictionary *userInfo = self.result ? @{OBASearchControllerUserInfoDataKey: self.result} : nil;

    [[NSNotificationCenter defaultCenter] postNotificationName:OBASearchControllerDidUpdateNotification
                                                        object:self
                                                      userInfo:userInfo];

    id<OBASearchControllerDelegate> delegate = _delegate;
    if (delegate) {
        [delegate handleSearchControllerUpdate:self.result];
    }
}

- (void)fireError:(NSError *)error {
    self.error = error;

    id delegate = _delegate;
    if (delegate && [delegate respondsToSelector:@selector(handleSearchControllerError:)]) {
        [delegate handleSearchControllerError:error];
    }
}

@end
