#import "OBAReportProblemWithTripV2.h"


@implementation OBAReportProblemWithTripV2

@synthesize tripId;
@synthesize serviceDate;
@synthesize stopId;
@synthesize data;
@synthesize userComment;
@synthesize userOnVehicle;
@synthesize userVehicleNumber;
@synthesize userLocation;

- (void) dealloc {
	self.tripId = nil;
	self.stopId = nil;
	self.data = nil;
	self.userComment = nil;
	self.userVehicleNumber = nil;
	self.userLocation = nil;	
	[super dealloc];
}


@end
