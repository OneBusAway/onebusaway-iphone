#import "OBAHasReferencesV2.h"
#import "OBAStopV2.h"
#import "OBAArrivalAndDepartureV2.h"
#import "OBAHasServiceAlerts.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalsAndDeparturesForStopV2 : OBAHasReferencesV2<OBAHasServiceAlerts>
@property(nonatomic,strong) NSString *stopId;
@property(nonatomic,weak,readonly) OBAStopV2 *stop;
@property(nonatomic,strong,readonly) NSArray<OBAArrivalAndDepartureV2*> *arrivalsAndDepartures;

- (void)addArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;
@end

NS_ASSUME_NONNULL_END