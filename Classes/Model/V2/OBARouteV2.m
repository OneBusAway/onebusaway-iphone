#import "OBARouteV2.h"


@implementation OBARouteV2 

@synthesize routeId = _routeId;
@synthesize shortName = _shortName;
@synthesize longName = _longName;
@synthesize routeType = _routeType;
@synthesize agencyId = _agencyId;

- (void) dealloc {
	[_routeId release];
	[_shortName release];
	[_longName release];
	[_routeType release];
	[_agencyId release];
	[super dealloc];
}

- (OBAAgencyV2*) agency {
	OBAReferencesV2 * refs = [self references];
	return [refs getAgencyForId:_agencyId];
}

- (NSString *) safeShortName {
	NSString * name = self.shortName;
	if( name )
		return name;
	return self.longName;	
}

- (NSComparisonResult) compareUsingName:(OBARouteV2*)aRoute {
	NSString * name1 = [self safeShortName];
	NSString * name2 = [aRoute safeShortName];
	return [name1 compare:name2 options:NSNumericSearch];
}

@end