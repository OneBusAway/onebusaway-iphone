#import "OBATripContinuationMapAnnotation.h"


@implementation OBATripContinuationMapAnnotation

@synthesize tripInstance = _tripInstance;

- (id) initWithTitle:(NSString*)title tripInstance:(OBATripInstanceRef*)tripInstance location:(CLLocationCoordinate2D)location {
	if( self = [super init] ) {
		_title = [title retain]; 
		_tripInstance = [tripInstance retain];
		_location = location;
	}
	return self;
}

- (void) dealloc {
	[_title release];
	[_tripInstance release];
	[super dealloc];
}

- (NSString*) title {
	return _title;
}

- (CLLocationCoordinate2D) coordinate {
	return _location;
}

@end
