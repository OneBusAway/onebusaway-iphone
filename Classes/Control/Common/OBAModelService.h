#import "OBAModelDAO.h"
#import "OBAModelFactory.h"
#import "OBADataSourceConfig.h"
#import "OBAJsonDataSource.h"
#import "OBALocationManager.h"

#import "OBAReferencesV2.h"
#import "OBAStopV2.h"
#import "OBANavigationTarget.h"
#import "OBAPlacemark.h"
#import "OBATripInstanceRef.h"
#import "OBAArrivalAndDepartureInstanceRef.h"
#import "OBAReportProblemWithStopV2.h"
#import "OBAReportProblemWithTripV2.h"


@protocol OBAModelServiceRequest <NSObject>
- (void) cancel;
@end

@protocol OBAModelServiceDelegate <NSObject>
- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context;
@optional
- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context;
- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context;
- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context;
@end


@interface OBAModelService : NSObject {
	OBAReferencesV2 * _references;
	OBAModelDAO * _modelDao;
	OBAModelFactory * _modelFactory;
	OBAJsonDataSource * _obaJsonDataSource;
	OBAJsonDataSource * _googleMapsJsonDataSource;
	OBALocationManager * _locationManager;
}

@property (nonatomic,retain) OBAReferencesV2 * references;
@property (nonatomic,retain) OBAModelDAO * modelDao;
@property (nonatomic,retain) OBAModelFactory * modelFactory;
@property (nonatomic,retain) OBAJsonDataSource * obaJsonDataSource;
@property (nonatomic,retain) OBAJsonDataSource * googleMapsJsonDataSource;
@property (nonatomic,retain) OBALocationManager * locationManager;


- (id<OBAModelServiceRequest>) requestStopForId:(NSString*)stopId withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;
- (id<OBAModelServiceRequest>) requestStopWithArrivalsAndDeparturesForId:(NSString*)stopId withMinutesBefore:(NSUInteger)minutesBefore withMinutesAfter:(NSUInteger)minutesAfter withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;

- (id<OBAModelServiceRequest>) requestStopsForRegion:(MKCoordinateRegion)region withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;
- (id<OBAModelServiceRequest>) requestStopsForQuery:(NSString*)stopQuery withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;
- (id<OBAModelServiceRequest>) requestStopsForRoute:(NSString*)routeId withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;
- (id<OBAModelServiceRequest>) requestStopsForPlacemark:(OBAPlacemark*)placemark withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;

- (id<OBAModelServiceRequest>) requestRoutesForQuery:(NSString*)routeQuery withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;
- (id<OBAModelServiceRequest>) placemarksForAddress:(NSString*)address withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;

- (id<OBAModelServiceRequest>) requestAgenciesWithCoverageWithDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;

- (id<OBAModelServiceRequest>) requestArrivalAndDepartureForStop:(OBAArrivalAndDepartureInstanceRef*)instance withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;
- (id<OBAModelServiceRequest>) requestTripDetailsForTripInstance:(OBATripInstanceRef*)tripInstance withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;

- (id<OBAModelServiceRequest>) requestVehicleForId:(NSString*)vehicleId withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;

- (id<OBAModelServiceRequest>) requestShapeForId:(NSString*)shapeId withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;

- (id<OBAModelServiceRequest>) reportProblemWithStop:(OBAReportProblemWithStopV2*)problem withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;
- (id<OBAModelServiceRequest>) reportProblemWithTrip:(OBAReportProblemWithTripV2*)problem withDelegate:(id<OBAModelServiceDelegate>)delegate withContext:(id)context;

@end
