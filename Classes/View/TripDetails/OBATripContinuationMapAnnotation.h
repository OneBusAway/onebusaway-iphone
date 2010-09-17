@interface OBATripContinuationMapAnnotation : NSObject <MKAnnotation> {
	NSString * _title;
	NSString * _tripId;
	CLLocationCoordinate2D _location;
}

- (id) initWithTitle:(NSString*)title tripId:(NSString*)tripId location:(CLLocationCoordinate2D)location;

@property (nonatomic,readonly) NSString * tripId;

@end
