//
//  OBARegionChangeRequest.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/7/12.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OBARegionChangeRequestType) {
    OBARegionChangeRequestTypeUser=0,
    OBARegionChangeRequestTypeProgramatic=1
};


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

