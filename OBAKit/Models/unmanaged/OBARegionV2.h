//
//  OBARegionV2.h
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/22/13.
//
//
@import MapKit;
#import "OBARegionBoundsV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBARegionV2 : NSObject<NSCoding>
@property(nonatomic,strong) NSString * siriBaseUrl;
@property(nonatomic,strong) NSString * obaVersionInfo;
@property(nonatomic,strong) NSString * language;
@property(nonatomic,strong) NSArray * bounds;
@property(nonatomic,strong) NSString * contactEmail;
@property(nonatomic,strong) NSString * twitterUrl;
@property(nonatomic,strong) NSString * obaBaseUrl;
@property(nonatomic,strong) NSString * facebookUrl;
@property(nonatomic,strong) NSString * regionName;
@property(nonatomic,assign) BOOL supportsSiriRealtimeApis;
@property(nonatomic,assign) BOOL supportsObaRealtimeApis;
@property(nonatomic,assign) BOOL supportsObaDiscoveryApis;
@property(nonatomic,assign) BOOL active;
@property(nonatomic,assign) BOOL experimental;
@property(nonatomic,assign) NSInteger identifier;

- (void)addBound:(OBARegionBoundsV2*)bound;
- (CLLocationDistance)distanceFromLocation:(CLLocation*)location;
- (MKMapRect)serviceRect;

@end

NS_ASSUME_NONNULL_END