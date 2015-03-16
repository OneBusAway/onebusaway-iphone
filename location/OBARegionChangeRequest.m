//
//  OBARegionChangeRequest.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/7/12.
//
//

#import "OBARegionChangeRequest.h"
#import "OBASphericalGeometryLibrary.h"

@interface OBARegionChangeRequest ()
@property(readwrite) OBARegionChangeRequestType type;
@property(readwrite) MKCoordinateRegion region;
@property(strong,readwrite) NSDate * timestamp;
@end

@implementation OBARegionChangeRequest

- (id) initWithRegion:(MKCoordinateRegion)region type:(OBARegionChangeRequestType)type {

    self = [super init];

    if( self ) {
        self.region = region;
        self.type = type;
        self.timestamp = [[NSDate alloc] init];
    }
    return self;
}


- (double) compareRegion:(MKCoordinateRegion)region {
    return [OBASphericalGeometryLibrary getDistanceFromRegion:self.region toRegion:region];
}

@end