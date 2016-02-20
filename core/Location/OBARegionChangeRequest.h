//
//  OBARegionChangeRequest.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/7/12.
//
//

@import MapKit;

typedef NS_ENUM(NSInteger, OBARegionChangeRequestType) {
    OBARegionChangeRequestTypeUser=0,
    OBARegionChangeRequestTypeProgrammatic=1
};

NS_ASSUME_NONNULL_BEGIN

@interface OBARegionChangeRequest : NSObject
{
    NSDate * _timestamp;
    OBARegionChangeRequestType _type;
    MKCoordinateRegion _region;
}

- (id) initWithRegion:(MKCoordinateRegion)region type:(OBARegionChangeRequestType)type;
- (double) compareRegion:(MKCoordinateRegion)region;

@property(readonly) OBARegionChangeRequestType type;
@property(readonly) MKCoordinateRegion region;
@property(strong,readonly) NSDate * timestamp;

@end

NS_ASSUME_NONNULL_END