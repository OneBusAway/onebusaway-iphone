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

#import <OBAKit/OBANavigationTarget.h>
#import <OBAKit/NSCoder+OBAAdditions.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBARouteV2.h>

NSString * const kOBASearchTypeParameter = @"OBASearchTypeParameter";
NSString * const OBAStopIDNavigationTargetParameter = @"stopId";

NSString * const OBANavigationTargetSearchKey = @"OBANavigationTargetSearchKey";
NSString * const kOBASearchControllerSearchLocationParameter = @"OBASearchControllerSearchLocationParameter";
NSString * const OBAUserSearchQueryKey = @"OBAUserSearchQueryKey";

@interface OBANavigationTarget ()
@property(nonatomic,assign,readwrite) OBANavigationTargetType target;
@property(nonatomic,strong,readwrite) NSDictionary *parameters;
@end

@implementation OBANavigationTarget

- (instancetype)initWithTarget:(OBANavigationTargetType)target parameters:(nullable NSDictionary*)parameters {
    if (self = [super init]) {
        _target = target;
        _parameters = parameters ?: @{};
    }
    return self;
}

+ (instancetype)navigationTarget:(OBANavigationTargetType)target {
    return [self navigationTarget:target parameters:@{}];
}

+ (instancetype)navigationTarget:(OBANavigationTargetType)target parameters:(NSDictionary*)parameters {
    return [[self alloc] initWithTarget:target parameters:parameters];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder*)coder {
    if (self = [super init]) {
        _target = [coder oba_decodeInteger:@selector(target)];
        _parameters = [NSMutableDictionary dictionaryWithDictionary:[coder oba_decodeObject:@selector(parameters)]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder oba_encodeInteger:_target forSelector:@selector(target)];
    [coder oba_encodeObject:_parameters forSelector:@selector(parameters)];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    OBANavigationTarget *target = [[self.class allocWithZone:zone] init];
    target->_target = _target;
    target->_parameters = [_parameters copyWithZone:zone];

    return target;
}

#pragma mark - Public

- (OBASearchType)searchType {
    return [self.parameters[kOBASearchTypeParameter] integerValue];
}

- (id)searchArgument {
    return self.parameters[OBANavigationTargetSearchKey];
}

- (NSString*)userFacingSearchQuery {
    return [self.parameters[OBAUserSearchQueryKey] description];
}

- (void)setObject:(id)object forParameter:(NSString*)parameter {
    OBAGuard(object && parameter) else {
        return;
    }

    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:self.parameters];
    d[parameter] = object;

    self.parameters = [NSDictionary dictionaryWithDictionary:d];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, @{@"Parameters": self.parameters, @"Search Type": NSStringFromOBASearchType(self.searchType)}];
}

@end

@implementation OBANavigationTarget (Builders)

+ (instancetype)navigationTargetForSearchNone {
    return [self navigationTargetForSearchType:OBASearchTypeNone];
}

+ (instancetype)navigationTargetForSearchLocationRegion:(MKCoordinateRegion)region {
    NSData * data = [NSData dataWithBytes:&region length:sizeof(MKCoordinateRegion)];
    return [self navigationTargetForSearchType:OBASearchTypeRegion argument:data];
}

+ (instancetype)navigationTargetForSearchRoute:(NSString*)routeQuery {
    return [self navigationTargetForSearchType:OBASearchTypeRoute argument:routeQuery];
}

+ (instancetype)navigationTargetForRoute:(OBARouteV2*)route {
    NSString *str = OBALocalized(@"navigation_target.search_query.route_format", @"e.g. Search for Route: <Route Number>");
    NSString *searchQuery = [NSString stringWithFormat:str, route.safeShortName];

    return [self navigationTargetForSearchType:OBASearchTypeStops
                                      argument:route.routeId
                               extraParameters:@{OBAUserSearchQueryKey: searchQuery}];
}

+ (instancetype)navigationTargetForSearchAddress:(NSString*)addressQuery {
    return [self navigationTargetForSearchType:OBASearchTypeAddress argument:addressQuery];
}

+ (instancetype)navigationTargetForSearchPlacemark:(OBAPlacemark*)placemark {
    return [self navigationTargetForSearchType:OBASearchTypePlacemark argument:placemark];
}

+ (instancetype)navigationTargetForStopID:(NSString*)stopID {
    return [self navigationTargetForSearchType:OBASearchTypeStopId argument:stopID];
}

+ (instancetype)navigationTargetForStopIDSearch:(NSString*)stopID {
    return [self navigationTargetForSearchType:OBASearchTypeStopIdSearch argument:stopID];
}

+ (instancetype)navigationTargetForRegionalAlert:(OBARegionalAlert*)regionalAlert {
    OBANavigationTarget *target = [self navigationTargetForSearchType:OBASearchTypeRegionalAlert argument:regionalAlert];
    target.target = OBANavigationTargetTypeContactUs;

    return target;
}

+ (instancetype)navigationTargetForSearchType:(OBASearchType)searchType {
    return [self navigationTargetForSearchType:searchType argument:nil];
}

+ (instancetype)navigationTargetForSearchType:(OBASearchType)searchType argument:(nullable id)argument {
    return [self navigationTargetForSearchType:searchType argument:argument extraParameters:nil];
}

+ (instancetype)navigationTargetForSearchType:(OBASearchType)searchType argument:(nullable id)argument extraParameters:(nullable NSDictionary*)dictionary {
    dictionary = dictionary ?: @{};

    NSMutableDictionary * params = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    params[kOBASearchTypeParameter] = @(searchType);

    if (argument) {
        params[OBANavigationTargetSearchKey] = argument;
    }

    OBANavigationTarget *target = [self navigationTarget:OBANavigationTargetTypeSearchResults parameters:params];

    return target;
}

@end

