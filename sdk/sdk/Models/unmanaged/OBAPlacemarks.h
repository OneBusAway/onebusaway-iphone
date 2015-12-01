#import "OBAPlacemark.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAPlacemarks : NSObject {
    NSMutableArray * _placemarks;
    NSMutableArray * _attributions;
}

@property (nonatomic,readonly) NSArray * placemarks;
@property (nonatomic,readonly) NSArray * attributions;

- (void) addPlacemark:(OBAPlacemark*)placemark;
- (void) addAttribution:(NSString*)attribution;

@end

NS_ASSUME_NONNULL_END