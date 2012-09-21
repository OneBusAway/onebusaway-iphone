#import "OBAHasReferencesV2.h"
#import "OBATripV2.h"
#import "OBATripScheduleV2.h"
#import "OBATripStatusV2.h"
#import "OBATripInstanceRef.h"

@interface OBATripDetailsV2 : OBAHasReferencesV2 {
	NSMutableArray * _situationIds;
}

@property (nonatomic,strong) NSString * tripId;
@property (weak, nonatomic,readonly) OBATripV2 * trip;

@property (nonatomic) long long serviceDate;

@property (weak, nonatomic,readonly) OBATripInstanceRef * tripInstance;

@property (nonatomic,strong) OBATripScheduleV2 * schedule;
@property (nonatomic,strong) OBATripStatusV2 * status;

@property (weak, nonatomic,readonly) NSArray * situationIds;
@property (weak, nonatomic,readonly) NSArray * situations;

- (void) addSituationId:(NSString*)situationId;

@end
