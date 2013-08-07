//
//  OBARegionChangeRequest.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/7/12.
//
//

#import <Foundation/Foundation.h>

typedef enum  {
    OBARegionChangeRequestTypeUser=0,
    OBARegionChangeRequestTypeProgramatic=1
} OBARegionChangeRequestType;


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

