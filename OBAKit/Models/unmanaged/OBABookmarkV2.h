#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class OBARegionV2;
@class OBAStopV2;
@class OBABookmarkGroup;

NS_ASSUME_NONNULL_BEGIN

@interface OBABookmarkV2 : NSObject<NSCoding,MKAnnotation>
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *stopID;
@property(nonatomic,strong,nullable) OBABookmarkGroup *group;
@property(nonatomic,assign) NSInteger regionIdentifier;
@property(nonatomic,assign,readwrite) CLLocationCoordinate2D coordinate;

- (instancetype)initWithStop:(OBAStopV2*)stop region:(OBARegionV2*)region;
@end

NS_ASSUME_NONNULL_END
