//
//  OBARegionV2.h
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/22/13.
//
//

#import "OBARegionBoundsV2.h"

@interface OBARegionV2 : NSObject<NSCoding>
{
    NSMutableArray *_bounds;
}

@property (nonatomic, strong) NSString * siriBaseUrl;
@property (nonatomic, strong) NSString * obaVersionInfo;
@property (nonatomic, strong) NSString * language;
@property (nonatomic, strong) NSArray * bounds;
@property (nonatomic, strong) NSString * contactEmail;
@property (nonatomic, strong) NSString * twitterUrl;
@property (nonatomic, strong) NSString * obaBaseUrl;
@property (nonatomic, strong) NSString * facebookUrl;
@property (nonatomic, strong) NSString * regionName;

@property (nonatomic) BOOL supportsSiriRealtimeApis;
@property (nonatomic) BOOL supportsObaRealtimeApis;
@property (nonatomic) BOOL supportsObaDiscoveryApis;
@property (nonatomic) BOOL active;
@property (nonatomic) BOOL experimental;
@property (nonatomic) NSInteger id_number;

- (void)addBound:(OBARegionBoundsV2*)bound;
- (CLLocationDistance)distanceFromLocation:(CLLocation*)location;

@end
