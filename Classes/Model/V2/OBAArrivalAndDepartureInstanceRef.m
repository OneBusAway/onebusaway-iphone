#import "OBAArrivalAndDepartureInstanceRef.h"


@implementation OBAArrivalAndDepartureInstanceRef

@synthesize tripInstance = _tripInstance;
@synthesize stopId = _stopId;
@synthesize stopSequence = _stopSequence;

- (id) initWithTripInstance:(OBATripInstanceRef*)tripInstance stopId:(NSString*)stopId stopSequence:(NSInteger)stopSequence {
	if( self = [super init] ) {
		_tripInstance = [tripInstance retain];
		_stopId = [stopId retain];
		_stopSequence = stopSequence;
	}
	return self;
}

+ (OBAArrivalAndDepartureInstanceRef*) refWithTripInstance:(OBATripInstanceRef*)tripInstance stopId:(NSString*)stopId stopSequence:(NSInteger)stopSequence {
	return [[[self alloc] initWithTripInstance:tripInstance stopId:stopId stopSequence:stopSequence] autorelease];
}

@end
