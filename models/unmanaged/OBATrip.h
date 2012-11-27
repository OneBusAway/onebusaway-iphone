//
//  OBATrip.h
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 10/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//


@interface OBATrip : NSObject {
    NSString * _tripId;
    NSString * _tripHeadsign;
    NSString * _routeShortName;
}

@property (nonatomic,strong) NSString * tripId;
@property (nonatomic,strong) NSString * tripHeadsign;
@property (nonatomic,strong) NSString * routeShortName;

@end
