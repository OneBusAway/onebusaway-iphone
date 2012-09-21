#import "OBARouteV2.h"


@implementation OBARouteV2 

@synthesize routeId;
@synthesize shortName;
@synthesize longName;
@synthesize routeType;
@synthesize agencyId;


- (OBAAgencyV2*) agency {
	OBAReferencesV2 * refs = [self references];
	return [refs getAgencyForId:self.agencyId];
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