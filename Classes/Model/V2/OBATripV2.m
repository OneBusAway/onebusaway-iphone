#import "OBATripV2.h"


@implementation OBATripV2

@synthesize tripId;
@synthesize routeId;
@synthesize routeShortName;
@synthesize tripShortName;
@synthesize tripHeadsign;
@synthesize serviceId;
@synthesize shapeId;
@synthesize directionId;

- (OBARouteV2*) route {
	OBAReferencesV2 * refs = self.references;
	return [refs getRouteForId:self.routeId];
}

- (NSString*) asLabel {
	OBARouteV2 * r = self.route;
	NSString * rShortName = self.routeShortName;
	if( ! rShortName )
		rShortName = [r safeShortName];
	NSString * headsign = self.tripHeadsign;
	if( ! headsign )
		headsign = r.longName;
	if( ! headsign )
		headsign = @"Headed somewhere...";
	
	return [NSString stringWithFormat:@"%@ - %@",rShortName,headsign];	
}

@end
