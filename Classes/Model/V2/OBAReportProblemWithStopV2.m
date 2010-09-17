#import "OBAReportProblemWithStopV2.h"


@implementation OBAReportProblemWithStopV2

@synthesize stopId;
@synthesize data;
@synthesize userComment;
@synthesize userLocation;

- (void) dealloc {
	self.stopId = nil;
	self.data = nil;
	self.userComment = nil;
	self.userLocation = nil;	
	[super dealloc];
}


@end
