#import "OBAArrivalsAndDeparturesForStopV2.h"


@implementation OBAArrivalsAndDeparturesForStopV2

@synthesize stopId = _stopId;
@synthesize arrivalsAndDepartures = _arrivalsAndDepartures;

-(id) initWithReferences:(OBAReferencesV2*)refs {
	if( self = [super initWithReferences:refs] ) {
		_arrivalsAndDepartures = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void) dealloc {
	[_stopId release];
	[_arrivalsAndDepartures release];
	[super dealloc];
}

-(OBAStopV2*) stop {
	OBAReferencesV2 * refs = [self references];
	return [refs getStopForId:_stopId];
}

- (void) addArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
	[_arrivalsAndDepartures addObject:arrivalAndDeparture];
}

@end