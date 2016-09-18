/*
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <OBAKit/OBARouteType.h>

@class OBARegionV2;
@class OBAStopV2;
@class OBABookmarkGroup;
@class OBAArrivalAndDepartureV2;
@class OBAArrivalsAndDeparturesForStopV2;

typedef NS_ENUM(NSUInteger, OBABookmarkVersion) {
    OBABookmarkVersion252 = 0,
    OBABookmarkVersion260,
};

NS_ASSUME_NONNULL_BEGIN

@interface OBABookmarkV2 : NSObject<NSCoding,NSCopying,MKAnnotation>
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *routeShortName;
@property(nonatomic,copy) NSString *stopId;
@property(nonatomic,copy) NSString *tripHeadsign;
@property(nonatomic,copy) NSString *routeID;
@property(nonatomic,copy,nullable) OBAStopV2 *stop;
@property(nonatomic,strong,nullable) OBABookmarkGroup *group;
@property(nonatomic,assign) NSInteger regionIdentifier;
@property(nonatomic,assign,readonly) OBARouteType routeType;
@property(nonatomic,assign) NSUInteger sortOrder;
@property(nonatomic,assign) OBABookmarkVersion bookmarkVersion;

/**
 Used to create OBABookmarkVersion260-type bookmarks.
 */
- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture region:(OBARegionV2*)region;

/**
 Used to create OBABookmarkVersion252-type bookmarks.
 */
- (instancetype)initWithStop:(OBAStopV2*)stop region:(OBARegionV2*)region;

/**
 Tests whether this is a valid bookmark model.

 @return True if it is valid and false if it is invalid.
 */
- (BOOL)isValidModel;

/**
 Basically, an -isEqual: for comparing bookmarks to OBAArrivalAndDepartureV2 objects.
 */
- (BOOL)matchesArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;

/**
 Extracts all OBAArrivalAndDepartureV2 objects from `dep` that match this bookmark.
 @param dep The arrivals and departures object to filter.

 @return A filtered list of OBAArrivalAndDepartureV2 that match this bookmark.
 */
- (NSArray<OBAArrivalAndDepartureV2*>*)matchingArrivalsAndDeparturesForStop:(OBAArrivalsAndDeparturesForStopV2*)dep;

@end

NS_ASSUME_NONNULL_END
