//
//  OBARegionBoundsV2.h
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/22/13.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBARegionBoundsV2 : NSObject<NSCoding>

@property (nonatomic) double lat;
@property (nonatomic) double latSpan;
@property (nonatomic) double lon;
@property (nonatomic) double lonSpan;
@end

NS_ASSUME_NONNULL_END