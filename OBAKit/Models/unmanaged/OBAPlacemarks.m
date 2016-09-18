#import <OBAKit/OBAPlacemarks.h>

@implementation OBAPlacemarks

- (id) init {
    self = [super init];
    if( self ) {
        _placemarks = [[NSMutableArray alloc] init];
        _attributions = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addPlacemark:(OBAPlacemark*)placemark {
    [_placemarks addObject:placemark];
}

- (void) addAttribution:(NSString*)attribution {
    [_attributions addObject:attribution];
}

@end
