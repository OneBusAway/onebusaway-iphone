#import "OBAHasReferencesV2.h"
#import "OBALegV2.h"
#import "OBATransitLegV2.h"


@interface OBAItineraryV2 : OBAHasReferencesV2 {
    NSMutableArray * _legs;
}

@property (nonatomic,strong) NSDate * startTime;
@property (nonatomic,strong) NSDate * endTime;
@property (nonatomic,readonly) NSArray * legs;
@property (nonatomic) double probability;
@property (nonatomic) BOOL selected;
@property (nonatomic,strong) NSDictionary * rawData;

- (void) addLeg:(OBALegV2*)leg;

- (OBALegV2*) firstTransitLeg;

@end
