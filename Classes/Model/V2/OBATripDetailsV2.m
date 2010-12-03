#import "OBATripDetailsV2.h"


@implementation OBATripDetailsV2

@synthesize tripId;
@synthesize serviceDate;
@synthesize schedule;
@synthesize status;

- (id) initWithReferences:(OBAReferencesV2*)refs {
	if( self = [super initWithReferences:refs]) {
		_situationIds = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[_situationIds release];
	[super dealloc];
}


- (OBATripV2*) trip {
	OBAReferencesV2 * refs = self.references;
	return [refs getTripForId:self.tripId];
}

- (OBATripInstanceRef *) tripInstance {
	return [OBATripInstanceRef tripInstance:self.tripId serviceDate:self.serviceDate vehicleId:self.status.vehicleId];
}

- (NSArray*) situationIds {
	return _situationIds;
}

- (NSArray*) situations {
	
	NSMutableArray * rSituations = [NSMutableArray array];
	
	OBAReferencesV2 * refs = self.references;
	
	for( NSString * situationId in self.situationIds ) {
		OBASituationV2 * situation = [refs getSituationForId:situationId];
		if( situation )
			[rSituations addObject:situation];
	}
	
	return rSituations;
}

- (void) addSituationId:(NSString*)situationId {
	[_situationIds addObject:situationId];
}

@end
