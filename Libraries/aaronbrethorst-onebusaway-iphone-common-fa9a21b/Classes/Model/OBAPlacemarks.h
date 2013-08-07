#import "OBAPlacemark.h"


@interface OBAPlacemarks : NSObject {
    NSMutableArray * _placemarks;
    NSMutableArray * _attributions;
}

@property (nonatomic,readonly) NSArray * placemarks;
@property (nonatomic,readonly) NSArray * attributions;

- (void) addPlacemark:(OBAPlacemark*)placemark;
- (void) addAttribution:(NSString*)attribution;

@end
