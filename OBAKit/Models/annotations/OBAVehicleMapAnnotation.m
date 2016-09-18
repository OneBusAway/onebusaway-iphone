#import <OBAKit/OBAVehicleMapAnnotation.h>
#import <OBAKit/OBADateHelpers.h>

@implementation OBAVehicleMapAnnotation

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
    return [OBADateHelpers formatShortTimeNoDate:[NSDate dateWithTimeIntervalSince1970:_tripStatus.lastUpdateTime/1000.0]];
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
