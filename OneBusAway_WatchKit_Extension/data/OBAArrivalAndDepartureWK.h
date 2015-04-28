//
//  OBAArrivalAndDepartureWK.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/13/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import "OBAModelObjectWK.h"

@interface OBAArrivalAndDepartureWK : OBAModelObjectWK

@property (nonatomic, assign) double distanceFromStop;

@property (nonatomic, assign) long long predictedArrivalTime;
@property (nonatomic, assign) long long predictedDepartureTime;
@property (nonatomic, assign) long long scheduledArrivalTime;
@property (nonatomic, assign) long long scheduledDepartureTime;

@property (nonatomic, copy) NSString *tripId;

@property (nonatomic, copy) NSString *routeId;
@property (nonatomic, copy) NSString *routeShortName;

@property (nonatomic, copy) NSString *stopId;

@property (nonatomic, readonly) NSTimeInterval bestTime;
@property (nonatomic, readonly) NSDate *time;

@end
