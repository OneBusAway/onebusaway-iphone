#import "OBADiversionViewController.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBACoordinateBounds.h"
#import "OBAPlacemark.h"


@interface OBADiversionViewController ()


@property (nonatomic, strong) NSString *tripEncodedPolyline;

@property (nonatomic, strong) MKPolyline *routePolyline;
@property (nonatomic, strong) MKPolylineView *routePolylineView;

@property (nonatomic, strong) MKPolyline *reroutePolyline;
@property (nonatomic, strong) MKPolylineView *reroutePolylineView;

@property (nonatomic, strong) id<OBAModelServiceRequest> request;

- (MKMapView *)mapView;


@end

@implementation OBADiversionViewController

+ (OBADiversionViewController *)loadFromNibWithappDelegate:(OBAApplicationDelegate *)context {
    NSArray *wired = [[NSBundle mainBundle] loadNibNamed:@"OBADiversionViewController" owner:context options:nil];
    OBADiversionViewController *controller = wired[0];

    return controller;
}

- (void)dealloc {
    [self.request cancel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    MKMapView *mv = [self mapView];
    NSArray *points = [OBASphericalGeometryLibrary decodePolylineString:self.diversionPath];

    _reroutePolyline = [OBASphericalGeometryLibrary createMKPolylineFromLocations:points];

    [mv addOverlay:_reroutePolyline];

    OBACoordinateBounds *bounds = [OBASphericalGeometryLibrary boundsForLocations:points];

    if (![bounds empty]) {
        [mv setRegion:bounds.region];
    }

    NSString *shapeId = [[self.args[@"arrivalAndDeparture"] trip] shapeId];

    if (!self.tripEncodedPolyline && shapeId) {
        [self requestShapeForID:shapeId];
    }
}

- (void)requestShapeForID:(NSString *)shapeId {
    OBAApplicationDelegate *context = self.appDelegate;
    OBAModelService *service = context.modelService;
    @weakify(self);
    self.request = [service requestShapeForId:shapeId completionBlock:^(id jsonData, NSUInteger responseCode, NSError *error) {
        @strongify(self);

        if (!jsonData) {
            return;
        }

        self.tripEncodedPolyline = jsonData;
        NSArray *points = [OBASphericalGeometryLibrary decodePolylineString:self.tripEncodedPolyline];

        CLLocationCoordinate2D *pointArr = malloc(sizeof(CLLocationCoordinate2D) * points.count);

        for (NSInteger i = 0; i < points.count; i++) {
            CLLocation *location = points[i];
            CLLocationCoordinate2D p = location.coordinate;
            pointArr[i] = p;
        }

        self.routePolyline = [MKPolyline polylineWithCoordinates:pointArr count:points.count];
        free(pointArr);
        [self.mapView addOverlay:self.routePolyline];
    }];
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[OBAPlacemark class]]) {
        static NSString *viewId = @"DiversionView";
        MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:viewId];

        if (view == nil) {
            view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
        }

        view.canShowCallout = NO;
        return view;
    }

    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay {
    MKOverlayView *overlayView = nil;

    if (overlay == _reroutePolyline) {
        //if we have not yet created an overlay view for this overlay, create it now.
        if (_reroutePolylineView == nil) {
            _reroutePolylineView = [[MKPolylineView alloc] initWithPolyline:_reroutePolyline];
            _reroutePolylineView.fillColor = [UIColor redColor];
            _reroutePolylineView.strokeColor = [UIColor redColor];
            _reroutePolylineView.lineWidth = 5;
        }

        overlayView = _reroutePolylineView;
    }
    else if (overlay == _routePolyline) {
        //if we have not yet created an overlay view for this overlay, create it now.
        if (_routePolylineView == nil) {
            _routePolylineView = [[MKPolylineView alloc] initWithPolyline:_routePolyline];
            _routePolylineView.fillColor = [UIColor blackColor];
            _routePolylineView.strokeColor = [UIColor blackColor];
            _routePolylineView.lineWidth = 5;
        }

        overlayView = _routePolylineView;
    }

    return overlayView;
}

- (MKMapView *)mapView {
    return (MKMapView *)self.view;
}

@end
