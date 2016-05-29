#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "OBARouteType.h"

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

- (instancetype)initWithArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture region:(OBARegionV2*)region;

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
