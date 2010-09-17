//
//  OBASetLocationPropertyJsonDigesterRule.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 10/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OBASetLocationPropertyJsonDigesterRule.h"


@implementation OBASetLocationPropertyJsonDigesterRule

- (void) begin:(id<OBAJsonDigesterContext>)context name:(NSString*)name value:(id)value {
	
	if( ! [value isKindOfClass:[NSDictionary class]] )
		return;
	
	NSDictionary * dictionary = (NSDictionary*)value;
	
	NSNumber * latitude = [dictionary objectForKey:@"lat"];
	NSNumber * longitude = [dictionary objectForKey:@"lon"];
	
	CLLocation * location = [[[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]] autorelease];
	[super begin:context name:name value:location];
}


@end
