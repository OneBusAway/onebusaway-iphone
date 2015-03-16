#import "OBAHasReferencesV2.h"
#import "OBATransitLegV2.h"
#import "OBAStreetLegV2.h"


@interface OBALegV2 : OBAHasReferencesV2 {
    NSMutableArray * _streetLegs;
}

@property (nonatomic,strong) NSDate * startTime;
@property (nonatomic,strong) NSDate * endTime;
@property (nonatomic,strong) NSString * mode;
@property (nonatomic) double distance;

@property (nonatomic,strong) OBATransitLegV2 * transitLeg;
@property (nonatomic,readonly) NSArray * streetLegs;

- (void) addStreetLeg:(OBAStreetLegV2*)streetLeg;

@end
