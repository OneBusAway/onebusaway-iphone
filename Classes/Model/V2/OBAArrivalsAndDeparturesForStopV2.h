#import "OBAHasReferencesV2.h"
#import "OBAStopV2.h"
#import "OBAArrivalAndDepartureV2.h"


@interface OBAArrivalsAndDeparturesForStopV2 : OBAHasReferencesV2 {
	NSString * _stopId;
	NSMutableArray * _arrivalsAndDepartures;
	NSMutableArray * _situationIds;
}

@property (nonatomic,retain) NSString * stopId;
@property (nonatomic,readonly) OBAStopV2 * stop;
@property (nonatomic,readonly) NSArray * arrivalsAndDepartures;
@property (nonatomic,readonly) NSArray * situationIds;
@property (nonatomic,readonly) NSArray * situations;

- (void) addArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;
- (void) addSituationId:(NSString*)situationId;

@end
