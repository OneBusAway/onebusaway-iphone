#import "OBAModelDAO.h"
#import "OBAModelFactory.h"
#import "OBADataSourceConfig.h"
#import "OBAJsonDataSource.h"
#import "OBALocationManager.h"

#import "OBAReferencesV2.h"
#import "OBAStopV2.h"
#import "OBAPlacemark.h"
#import "OBATripInstanceRef.h"
#import "OBAArrivalAndDepartureInstanceRef.h"
#import "OBAReportProblemWithStopV2.h"
#import "OBAReportProblemWithTripV2.h"


@protocol OBAModelServiceRequest <NSObject>
- (void)cancel;
@end


@interface OBAModelService : NSObject

@property (nonatomic, strong) OBAReferencesV2 *references;
@property (nonatomic, strong) OBAModelDAO *modelDao;
@property (nonatomic, strong) OBAModelFactory *modelFactory;
@property (nonatomic, strong) OBAJsonDataSource *obaJsonDataSource;
@property (nonatomic, strong) OBAJsonDataSource *obaRegionJsonDataSource;
@property (nonatomic, strong) OBAJsonDataSource *googleMapsJsonDataSource;
@property (nonatomic, strong) OBAJsonDataSource *googlePlacesJsonDataSource;
@property (nonatomic, strong) OBALocationManager *locationManager;

@property (nonatomic, strong) NSData *deviceToken;


- (id<OBAModelServiceRequest>)requestStopForId:(NSString *)stopId completionBlock:(OBADataSourceCompletion)completion;
- (id<OBAModelServiceRequest>)requestStopWithArrivalsAndDeparturesForId:(NSString *)stopId withMinutesBefore:(NSUInteger)minutesBefore withMinutesAfter:(NSUInteger)minutesAfter completionBlock:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)requestStopsForRegion:(MKCoordinateRegion)region completionBlock:(OBADataSourceCompletion)completion;
- (id<OBAModelServiceRequest>)requestStopsForQuery:(NSString *)stopQuery completionBlock:(OBADataSourceCompletion)completion;
- (id<OBAModelServiceRequest>)requestStopsForQuery:(NSString *)stopQuery withRegion:(CLRegion *)region completionBlock:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)requestStopsForRoute:(NSString *)routeId completionBlock:(OBADataSourceCompletion)completion;
- (id<OBAModelServiceRequest>)requestStopsForPlacemark:(OBAPlacemark *)placemark completionBlock:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)requestRoutesForQuery:(NSString *)routeQuery completionBlock:(OBADataSourceCompletion)completion;
- (id<OBAModelServiceRequest>)requestRoutesForQuery:(NSString *)routeQuery withRegion:(CLRegion *)region completionBlock:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)placemarksForAddress:(NSString *)address completionBlock:(OBADataSourceCompletion)completion;
- (id<OBAModelServiceRequest>)placemarksForPlace:(NSString *)name completionBlock:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)requestRegions:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)requestAgenciesWithCoverage:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)requestArrivalAndDepartureForStop:(OBAArrivalAndDepartureInstanceRef *)instance completionBlock:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)requestTripDetailsForTripInstance:(OBATripInstanceRef *)tripInstance completionBlock:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)requestVehicleForId:(NSString *)vehicleId completionBlock:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)requestShapeForId:(NSString *)shapeId completionBlock:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)reportProblemWithStop:(OBAReportProblemWithStopV2 *)problem completionBlock:(OBADataSourceCompletion)completion;
- (id<OBAModelServiceRequest>)reportProblemWithTrip:(OBAReportProblemWithTripV2 *)problem completionBlock:(OBADataSourceCompletion)completion;

- (id<OBAModelServiceRequest>)requestCurrentVehicleEstimatesForLocations:(NSArray *)locations completionBlock:(OBADataSourceCompletion)completion;
@end
