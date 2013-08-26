#import "OBADiversionViewController.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBACoordinateBounds.h"
#import "OBAPlacemark.h"


@interface OBADiversionViewController (Private)
- (MKMapView*) mapView;
@end


@implementation OBADiversionViewController

+(OBADiversionViewController*) loadFromNibWithappDelegate:(OBAApplicationDelegate*)context {
    NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBADiversionViewController" owner:context options:nil];
    OBADiversionViewController* controller = wired[0];
    return controller;
}

- (void)dealloc {
    [_request cancel];
}

- (void) viewWillAppear:(BOOL)animated {
    
    MKMapView * mv = [self mapView];
    NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:self.diversionPath];

    _reroutePolyline = [OBASphericalGeometryLibrary createMKPolylineFromLocations:points];

    [mv addOverlay:_reroutePolyline];

    OBACoordinateBounds * bounds = [OBASphericalGeometryLibrary boundsForLocations:points];
    if( ! [bounds empty] ) {
        [mv setRegion:bounds.region];
    }

    OBAArrivalAndDepartureV2 * ad = (self.args)[@"arrivalAndDeparture"];
    if( ad != nil && _tripEncodedPolyline == nil ) {
        OBATripV2 * trip = ad.trip;
        NSString * shapeId = trip.shapeId;
        if( shapeId ) {
            OBAApplicationDelegate * context = self.appDelegate;
            OBAModelService * service = context.modelService;
            _request = [service requestShapeForId:shapeId withDelegate:self withContext:nil];
        }
    }
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    if( [annotation isKindOfClass:[OBAPlacemark class]] ) {
        static NSString * viewId = @"DiversionView";
        MKPinAnnotationView * view = (MKPinAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
        if( view == nil ) {
            view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId];
        }
        view.canShowCallout = NO;
        return view;
    }
    return nil;
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id )overlay {

    MKOverlayView* overlayView = nil;
    
    if(overlay == _reroutePolyline)
    {
        //if we have not yet created an overlay view for this overlay, create it now.
        if(_reroutePolylineView == nil)
        {
            _reroutePolylineView = [[MKPolylineView alloc] initWithPolyline:_reroutePolyline];
            _reroutePolylineView.fillColor = [UIColor redColor];
            _reroutePolylineView.strokeColor = [UIColor redColor];
            _reroutePolylineView.lineWidth = 5;
        }
        
        overlayView = _reroutePolylineView;
    }
    else if( overlay == _routePolyline ) {
        
        //if we have not yet created an overlay view for this overlay, create it now.
        if(_routePolylineView == nil)
        {
            _routePolylineView = [[MKPolylineView alloc] initWithPolyline:_routePolyline];
            _routePolylineView.fillColor = [UIColor blackColor];
            _routePolylineView.strokeColor = [UIColor blackColor];
            _routePolylineView.lineWidth = 5;
        }
        
        overlayView = _routePolylineView;
        
    }
    
    return overlayView;    
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
    if( obj ) {
        _tripEncodedPolyline = obj;
        NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:_tripEncodedPolyline];
        
        CLLocationCoordinate2D* pointArr = malloc(sizeof(CLLocationCoordinate2D) * points.count);
        for (int i=0; i<points.count;i++) {
            CLLocation * location = points[i];
            CLLocationCoordinate2D p = location.coordinate;
            pointArr[i] = p;
        }
        
        _routePolyline = [MKPolyline polylineWithCoordinates:pointArr count:points.count];
        free(pointArr);
        MKMapView * mv = [self mapView];
        [mv addOverlay:_routePolyline];
    }
}


@end

@implementation OBADiversionViewController (Private)

- (MKMapView*) mapView {
    return (MKMapView*) self.view;            
}

@end

