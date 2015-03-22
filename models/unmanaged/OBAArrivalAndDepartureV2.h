#import "OBAHasReferencesV2.h"
#import "OBARouteV2.h"
#import "OBAStopV2.h"
#import "OBATripV2.h"
#import "OBAFrequencyV2.h"
#import "OBATripStatusV2.h"
#import "OBATripInstanceRef.h"
#import "OBAArrivalAndDepartureInstanceRef.h"


@interface OBAArrivalAndDepartureV2 : OBAHasReferencesV2 {
    NSMutableArray * _situationIds;
}

@property (nonatomic,strong) NSString * routeId;
@property (weak, nonatomic,readonly) OBARouteV2 * route;
@property (nonatomic,strong) NSString * routeShortName;

@property (nonatomic,strong) NSString * tripId;
@property (weak, nonatomic,readonly) OBATripV2 * trip;
@property (nonatomic,strong) NSString * tripHeadsign;
@property (nonatomic) long long serviceDate;

@property (weak, nonatomic,readonly) OBAArrivalAndDepartureInstanceRef * instance;
@property (weak, nonatomic,readonly) OBATripInstanceRef * tripInstance;

@property (nonatomic,strong) NSString * stopId;
@property (weak, nonatomic,readonly) OBAStopV2 * stop;
@property (nonatomic) NSInteger stopSequence;

@property (nonatomic,strong) OBATripStatusV2 * tripStatus;

@property (nonatomic,strong) OBAFrequencyV2 * frequency;

@property (nonatomic) BOOL predicted;

@property (nonatomic) long long scheduledArrivalTime;
@property (nonatomic) long long predictedArrivalTime;
@property (nonatomic,readonly) long long bestArrivalTime;

@property (nonatomic) long long scheduledDepartureTime;
@property (nonatomic) long long predictedDepartureTime;
@property (nonatomic,readonly) long long bestDepartureTime;

@property (nonatomic) double distanceFromStop;

@property (nonatomic,readonly) NSArray * situationIds;
@property (weak, nonatomic,readonly) NSArray * situations;

@property (nonatomic) NSInteger reportType;
@property (nonatomic, strong) NSString * reportId;
@property (nonatomic) BOOL busFull;

- (void) addSituationId:(NSString*)situationId;

@end
