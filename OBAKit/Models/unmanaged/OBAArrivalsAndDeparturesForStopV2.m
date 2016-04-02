#import "OBAArrivalsAndDeparturesForStopV2.h"
#import "OBASituationV2.h"

@interface OBAArrivalsAndDeparturesForStopV2 ()
@property(nonatomic,strong) NSMutableArray *arrivalsAndDeparturesM;
@property(nonatomic,strong) NSMutableArray *situationIds;
@end

@implementation OBAArrivalsAndDeparturesForStopV2

- (instancetype)initWithReferences:(OBAReferencesV2*)refs {
    self = [super initWithReferences:refs];
    if (self) {
        _arrivalsAndDeparturesM = [[NSMutableArray alloc] init];
        _situationIds = [[NSMutableArray alloc] init];
    }
    return self;
}

-(OBAStopV2*) stop {
    OBAReferencesV2 * refs = [self references];
    return [refs getStopForId:self.stopId];
}

#pragma mark - Public

- (void)addArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
    [self.arrivalsAndDeparturesM addObject:arrivalAndDeparture];
}

- (NSArray<OBAArrivalAndDepartureV2*>*)arrivalsAndDepartures {
    return [NSArray arrayWithArray:self.arrivalsAndDeparturesM];
}

#pragma mark - OBAHasServiceAlerts

- (NSArray<OBASituationV2*>*)situations {
    NSMutableArray *rSituations = [NSMutableArray array];

    for (NSString * situationId in self.situationIds) {
        OBASituationV2 * situation = [self.references getSituationForId:situationId];
        if (situation) {
            [rSituations addObject:situation];
        }
    }
    
    return rSituations;
}

- (void) addSituationId:(NSString*)situationId {
    [_situationIds addObject:situationId];
}

@end