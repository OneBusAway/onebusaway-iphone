#import "OBAHasReferencesV2.h"
#import "OBAItineraryV2.h"


@interface OBAItinerariesV2 : OBAHasReferencesV2 {
    NSMutableArray * _itineraries;
}

@property (nonatomic,readonly) NSArray * itineraries;

-(void) addItinerary:(OBAItineraryV2*)itinerary;

@end
