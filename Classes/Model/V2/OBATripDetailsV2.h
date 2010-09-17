#import "OBAHasReferencesV2.h"
#import "OBATripV2.h"
#import "OBATripScheduleV2.h"

@interface OBATripDetailsV2 : OBAHasReferencesV2 {
	
}

@property (nonatomic,retain) NSString * tripId;
@property (nonatomic,readonly) OBATripV2 * trip;

@property (nonatomic,retain) OBATripScheduleV2 * schedule;

@end
