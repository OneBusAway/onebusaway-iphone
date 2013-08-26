#import "OBAArrivalsAndDeparturesForStopV2.h"
#import "OBASituationV2.h"


@implementation OBAArrivalsAndDeparturesForStopV2

@synthesize arrivalsAndDepartures = _arrivalsAndDepartures;
@synthesize situationIds = _situationIds;

-(id) initWithReferences:(OBAReferencesV2*)refs {
    self = [super initWithReferences:refs];
    if( self ) {
        _arrivalsAndDepartures = [[NSMutableArray alloc] init];
        _situationIds = [[NSMutableArray alloc] init];
    }
    return self;
}


-(OBAStopV2*) stop {
    OBAReferencesV2 * refs = [self references];
    return [refs getStopForId:self.stopId];
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

- (void) addArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    [_arrivalsAndDepartures addObject:arrivalAndDeparture];
}

- (void) addSituationId:(NSString*)situationId {
    [_situationIds addObject:situationId];
}

@end