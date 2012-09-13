#import "OBAVehicleMapAnnotation.h"



@implementation OBAVehicleMapAnnotation

@synthesize showLastKnownLocation = _showLastKnownLocation;

- (id) initWithTripStatus:(OBATripStatusV2*)tripStatus {
	if( self = [super init] ) {
		_tripStatus = tripStatus;
	}
	return self;	
}

#pragma mark MKAnnotation

- (NSString*) title {
	if( ! _tripStatus.vehicleId )
		return NSLocalizedString(@"Vehicle",@"title");
	return [NSString stringWithFormat:@"%@: %@",NSLocalizedString(@"Vehicle",@"title"), _tripStatus.vehicleId];
}

- (NSString*) subtitle {

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];	
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:kCFDateFormatterNoStyle];	
	NSString * result = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_tripStatus.lastUpdateTime/1000.0]];
	
	return result;
}

- (CLLocationCoordinate2D) coordinate {
	if( _showLastKnownLocation ) {
		return _tripStatus.lastKnownLocation.coordinate;
	}
	else {
		return _tripStatus.location.coordinate;
	}
}

@end
