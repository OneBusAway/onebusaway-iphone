//
//  OBAStopWK.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/6/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAModelObjectWK.h"
#import <CoreLocation/CoreLocation.h>

@interface OBAStopWK : OBAModelObjectWK

@property (nonatomic, copy) NSString *stopId;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *direction;
@property (nonatomic, copy) id lat;
@property (nonatomic, copy) id lon;
@property (nonatomic, copy) NSArray *routeIds;    // NSString
@property (nonatomic, copy) NSString *detail;

@property (nonatomic, readonly) CLLocation *location;

@end
