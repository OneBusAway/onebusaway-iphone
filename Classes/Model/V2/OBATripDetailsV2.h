#import "OBAHasReferencesV2.h"
#import "OBATripV2.h"
#import "OBATripScheduleV2.h"
#import "OBATripStatusV2.h"
#import "OBATripInstanceRef.h"

@interface OBATripDetailsV2 : OBAHasReferencesV2 {
	NSMutableArray * _situationIds;
}

@property (nonatomic,retain) NSString * tripId;
@property (nonatomic,readonly) OBATripV2 * trip;

@property (nonatomic) long long serviceDate;

@property (nonatomic,readonly) OBATripInstanceRef * tripInstance;

@property (nonatomic,retain) OBATripScheduleV2 * schedule;
@property (nonatomic,retain) OBATripStatusV2 * status;

@property (nonatomic,readonly) NSArray * situationIds;
@property (nonatomic,readonly) NSArray * situations;

- (void) addSituationId:(NSString*)situationId;

@end
