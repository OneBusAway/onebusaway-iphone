#import "OBATripContinuationMapAnnotation.h"


@implementation OBATripContinuationMapAnnotation

@synthesize tripId = _tripId;

- (id) initWithTitle:(NSString*)title tripId:(NSString*)tripId location:(CLLocationCoordinate2D)location {
	if( self = [super init] ) {
		_title = [title retain]; 
		_tripId = [tripId retain];
		_location = location;
	}
	return self;
}

- (void) dealloc {
	[_title release];
	[_tripId release];
	[super dealloc];
}

- (NSString*) title {
	return _title;
}

- (CLLocationCoordinate2D) coordinate {
	return _location;
}

@end
