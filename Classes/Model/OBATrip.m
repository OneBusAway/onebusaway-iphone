//
//  OBATrip.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 10/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OBATrip.h"


@implementation OBATrip

@synthesize tripId = _tripId;
@synthesize tripHeadsign = _tripHeadsign;
@synthesize routeShortName = _routeShortName;

- (void) dealloc {
	[_tripId release];
	[_tripHeadsign release];
	[_routeShortName release];
	[super dealloc];
}


@end