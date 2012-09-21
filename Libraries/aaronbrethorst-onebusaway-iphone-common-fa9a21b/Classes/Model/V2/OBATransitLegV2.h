#import "OBAHasReferencesV2.h"
#import "OBATripV2.h"
#import "OBAStopV2.h"
#import "OBAFrequencyV2.h"
#import "OBAArrivalAndDepartureInstanceRef.h"

@interface OBATransitLegV2 : OBAHasReferencesV2 {
    
}

@property (nonatomic,strong) NSString * tripId;
@property (nonatomic) long long serviceDate;
@property (nonatomic,strong) NSString * vehicleId;
@property (nonatomic,strong) OBAFrequencyV2 * frequency;
@property (nonatomic,strong) NSString * fromStopId;
@property (nonatomic) NSInteger fromStopSequence;
@property (nonatomic,strong) NSString * toStopId;
@property (nonatomic) NSInteger toStopSequence;
@property (nonatomic,strong) NSString * tripHeadsign;
@property (nonatomic,strong) NSString * routeShortName;
@property (nonatomic,strong) NSString * routeLongName;
@property (nonatomic,strong) NSString * path;
@property (nonatomic) long long scheduledDepartureTime;
@property (nonatomic) long long predictedDepartureTime;
@property (nonatomic,readonly) long long bestDepartureTime;
@property (nonatomic) long long scheduledArrivalTime;
@property (nonatomic) long long predictedArrivalTime;
@property (nonatomic,readonly) long long bestArrivalTime;

@property (weak, nonatomic,readonly) OBATripV2 * trip;
@property (weak, nonatomic,readonly) OBAStopV2 * fromStop;
@property (weak, nonatomic,readonly) OBAStopV2 * toStop;

@property (weak, nonatomic,readonly) OBATripInstanceRef * tripInstanceRef;
@property (weak, nonatomic,readonly) OBAArrivalAndDepartureInstanceRef * departureInstanceRef;
@property (weak, nonatomic,readonly) OBAArrivalAndDepartureInstanceRef * arrivalInstanceRef;


@end
