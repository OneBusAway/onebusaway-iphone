#import "OBAHasReferencesV2.h"
#import "OBARouteV2.h"
#import "OBAStopV2.h"


@interface OBAArrivalAndDepartureV2 : OBAHasReferencesV2 {
	NSString * _routeId;
	NSString * _routeShortName;
	
	NSString * _tripId;
	NSString * _tripHeadsign;
	
	NSString * _stopId;
	
	long long _scheduledArrivalTime;
	long long _predictedArrivalTime;
	long long _scheduledDepartureTime;
	long long _predictedDepartureTime;	
}

@property (nonatomic,retain) NSString * routeId;
@property (nonatomic,readonly) OBARouteV2 * route;
@property (nonatomic,retain) NSString * routeShortName;

@property (nonatomic,retain) NSString * tripId;
@property (nonatomic,retain) NSString * tripHeadsign;
@property (nonatomic) long long serviceDate;

@property (nonatomic,retain) NSString * stopId;
@property (nonatomic,readonly) OBAStopV2 * stop;

@property (nonatomic) long long scheduledArrivalTime;
@property (nonatomic) long long predictedArrivalTime;
@property (nonatomic,readonly) long long bestArrivalTime;

@property (nonatomic) long long scheduledDepartureTime;
@property (nonatomic) long long predictedDepartureTime;
@property (nonatomic,readonly) long long bestDepartureTime;

@end
