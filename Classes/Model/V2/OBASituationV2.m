//
//  OBASituationV2.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 11/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OBASituationV2.h"


@implementation OBASituationV2

@synthesize situationId;
@synthesize creationTime;

@synthesize summary;
@synthesize description;
@synthesize advice;

@synthesize consequences;

@synthesize severity;
@synthesize sensitivity;

- (void) dealloc {
	
	self.situationId = nil;
	
	self.summary = nil;
	self.description = nil;
	self.advice = nil;
	
	self.consequences = nil;
	
	self.severity = nil;
	self.sensitivity = nil;
	
	[super dealloc];
}
@end
