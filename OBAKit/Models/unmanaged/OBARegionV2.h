//
//  OBARegionV2.h
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/22/13.
//
//
#import <MapKit/MapKit.h>
#import "OBARegionBoundsV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBARegionV2 : NSObject<NSCoding>
@property(nonatomic,copy,nullable) NSString * siriBaseUrl;
@property(nonatomic,copy,nullable) NSString * obaVersionInfo;
@property(nonatomic,copy,nullable) NSString * language;
@property(nonatomic,strong) NSArray * bounds;
@property(nonatomic,copy,nullable) NSString * contactEmail;
@property(nonatomic,copy,nullable) NSString * twitterUrl;
@property(nonatomic,copy) NSString * obaBaseUrl;
@property(nonatomic,copy,nullable) NSString * facebookUrl;
@property(nonatomic,copy) NSString * regionName;
@property(nonatomic,assign) BOOL supportsSiriRealtimeApis;
@property(nonatomic,assign) BOOL supportsObaRealtimeApis;
@property(nonatomic,assign) BOOL supportsObaDiscoveryApis;
@property(nonatomic,assign) BOOL active;
@property(nonatomic,assign) BOOL experimental;
@property(nonatomic,assign) NSInteger identifier;

/**
 Signifies that this was created in the RegionBuilderViewController
 */
@property(nonatomic,assign) BOOL custom;

- (void)addBound:(OBARegionBoundsV2*)bound;
- (CLLocationDistance)distanceFromLocation:(CLLocation*)location;
- (MKMapRect)serviceRect;

/**
 Tests whether this is a valid region object.
 */
- (BOOL)isValidModel;

/**
 obaBaseUrl converted into an NSURL
 */
@property(nonatomic,copy,readonly) NSURL *baseURL;

@end

NS_ASSUME_NONNULL_END
