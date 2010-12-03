#import "OBAReportProblemWithTripV2.h"


@implementation OBAReportProblemWithTripV2

@synthesize tripInstance;
@synthesize stopId;
@synthesize data;
@synthesize userComment;
@synthesize userOnVehicle;
@synthesize userVehicleNumber;
@synthesize userLocation;

- (void) dealloc {
	self.tripInstance = nil;
	self.stopId = nil;
	self.data = nil;
	self.userComment = nil;
	self.userVehicleNumber = nil;
	self.userLocation = nil;	
	[super dealloc];
}


@end
