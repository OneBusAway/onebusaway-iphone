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

@property (nonatomic, retain) NSString * siriBaseUrl;
@property (nonatomic, retain) NSString * obaVersionInfo;
@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSArray * bounds;
@property (nonatomic, retain) NSString * contactEmail;
@property (nonatomic, retain) NSString * obaBaseUrl;
@property (nonatomic, retain) NSString * regionName;

@property (nonatomic) BOOL supportsSiriRealtimeApis;
@property (nonatomic) BOOL supportsObaRealtimeApis;
@property (nonatomic) BOOL supportsObaDiscoveryApis;
@property (nonatomic) BOOL active;
@property (nonatomic) NSInteger id_number;

- (void)addBound:(OBARegionBoundsV2*)bound;
- (CLLocationDistance)distanceFromLocation:(CLLocation*)location;

@end
