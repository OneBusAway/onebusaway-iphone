#import "OBAHasReferencesV2.h"
#import "OBARouteV2.h"
#import "OBAStopV2.h"
#import "OBATripV2.h"
#import "OBAFrequencyV2.h"
#import "OBATripStatusV2.h"
#import "OBATripInstanceRef.h"
#import "OBAArrivalAndDepartureInstanceRef.h"
#import "OBADepartureStatus.h"
#import "OBAHasServiceAlerts.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalAndDepartureV2 : OBAHasReferencesV2<OBAHasServiceAlerts>

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
- (BOOL)hasRealTimeData;

@property (nonatomic) double distanceFromStop;
@property (nonatomic) NSInteger numberOfStopsAway;

/**
 Walks through a series of possible options for giving this arrival and departure a user-sensible name.

 @return A string (hopefully) suitable for presenting to the user.
 */
- (NSString*)bestAvailableName;

- (OBADepartureStatus)departureStatus;

- (NSString*)statusText;

/**
 How far off is this vehicle from its predicted, scheduled time?

 @return `NaN` when real time data is unavailable. Negative is early, positive is delayed.
 */
- (double)predictedDepatureTimeDeviationFromScheduleInMinutes;

/**
 How far away are we right now from the best departure time available to us? Uses real time data when available, and scheduled data otherwise.

 @return The number of minutes until departure, suitable to display to a user.
 */
- (NSInteger)minutesUntilBestDeparture;

@end

NS_ASSUME_NONNULL_END