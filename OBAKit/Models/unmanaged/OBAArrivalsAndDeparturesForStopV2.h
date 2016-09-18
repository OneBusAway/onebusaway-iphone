#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBAHasServiceAlerts.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalsAndDeparturesForStopV2 : OBAHasReferencesV2<OBAHasServiceAlerts>
@property(nonatomic,strong) NSString *stopId;
@property(nonatomic,weak,readonly) OBAStopV2 *stop;
@property(nonatomic,strong,readonly) NSArray<OBAArrivalAndDepartureV2*> *arrivalsAndDepartures;

- (void)addArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;
@end

NS_ASSUME_NONNULL_END
