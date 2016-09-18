#import <OBAKit/OBATripContinuationMapAnnotation.h>

@implementation OBATripContinuationMapAnnotation

- (id) initWithTitle:(NSString*)title tripInstance:(OBATripInstanceRef*)tripInstance location:(CLLocationCoordinate2D)location {
    if( self = [super init] ) {
        _title = title; 
        _tripInstance = tripInstance;
        _location = location;
    }
    return self;
}


- (NSString*) title {
    return _title;
}

- (CLLocationCoordinate2D) coordinate {
    return _location;
}

@end
