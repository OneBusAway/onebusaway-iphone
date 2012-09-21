#import "OBAHasReferencesV2.h"
#import "OBAStopV2.h"
#import "OBAArrivalAndDepartureV2.h"


@interface OBAArrivalsAndDeparturesForStopV2 : OBAHasReferencesV2 {
	NSMutableArray * _arrivalsAndDepartures;
	NSMutableArray * _situationIds;
}

@property (nonatomic,strong) NSString * stopId;
@property (weak, nonatomic,readonly) OBAStopV2 * stop;
@property (nonatomic,readonly) NSArray * arrivalsAndDepartures;
@property (nonatomic,readonly) NSArray * situationIds;
@property (weak, nonatomic,readonly) NSArray * situations;

- (void) addArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;
- (void) addSituationId:(NSString*)situationId;

@end
