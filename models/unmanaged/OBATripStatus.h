//
//  OBATripStatus.h
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 10/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//


#import "OBATrip.h"
#import "OBARoute.h"

@interface OBATripStatus : NSObject {
	OBATrip * _trip;
	OBARoute * _route;
	long long _serviceDate;
	CLLocation * _position;
	int _scheduleDeviation;
	BOOL _predicted;
}

@property (nonatomic,strong) OBATrip * trip;
@property (nonatomic,strong) OBARoute * route;
@property (nonatomic) long long serviceDate;
@property (nonatomic,strong) CLLocation * position;
@property (nonatomic) int scheduleDeviation;
@property (nonatomic) BOOL predicted;

@end
