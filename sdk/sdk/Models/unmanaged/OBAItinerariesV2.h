#import "OBAHasReferencesV2.h"
#import "OBAItineraryV2.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAItinerariesV2 : OBAHasReferencesV2 {
    NSMutableArray * _itineraries;
}

@property (nonatomic,readonly) NSArray * itineraries;

-(void) addItinerary:(OBAItineraryV2*)itinerary;

@end

NS_ASSUME_NONNULL_END