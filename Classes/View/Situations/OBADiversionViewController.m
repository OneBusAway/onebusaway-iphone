#import "OBADiversionViewController.h"
#import "OBAUIKit.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBACoordinateBounds.h"


@interface OBADiversionViewController (Private)

- (MKMapView*) mapView;

@end


@implementation OBADiversionViewController

@synthesize appContext;
@synthesize diversionPath;
@synthesize args;

+(OBADiversionViewController*) loadFromNibWithAppContext:(OBAApplicationContext*)context {
	NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBADiversionViewController" owner:context options:nil];
	OBADiversionViewController* controller = [wired objectAtIndex:0];
	return controller;
}

- (void)dealloc {
	[_request cancel];
	[_request release];
	
	[self.args release];
	[_tripEncodedPolyline release];
	[_routePolyline release];
	[_routePolylineView release];
	[_reroutePolyline release];
	[_reroutePolylineView release];
    [super dealloc];
}

- (void) viewWillAppear:(BOOL)animated {

	NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:self.diversionPath];
	OBACoordinateBounds * bounds = [[OBACoordinateBounds alloc] init];
	
	CLLocationCoordinate2D* pointArr = malloc(sizeof(CLLocationCoordinate2D) * points.count);
	for (int i=0; i<points.count;i++) {
		CLLocation * location = [points objectAtIndex:i];
		CLLocationCoordinate2D p = location.coordinate;
		[bounds addCoordinate:p];
		pointArr[i] = p;
	}
	
	_reroutePolyline = [[MKPolyline polylineWithCoordinates:pointArr count:points.count] retain];
	MKMapView * mv = [self mapView];
	[mv addOverlay:_reroutePolyline];
	
	if( ! [bounds empty] ) {
		[mv setRegion:bounds.region];
	}

	OBAArrivalAndDepartureV2 * ad = [self.args objectForKey:@"arrivalAndDeparture"];
	if( ad != nil && _tripEncodedPolyline == nil ) {
		OBATripV2 * trip = ad.trip;
		NSString * shapeId = trip.shapeId;
		if( shapeId ) {
			OBAApplicationContext * context = self.appContext;
			OBAModelService * service = context.modelService;
			_request = [[service requestShapeForId:shapeId withDelegate:self withContext:nil] retain];
		}
	}
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
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
		_tripEncodedPolyline = [obj retain];
		NSArray * points = [OBASphericalGeometryLibrary decodePolylineString:_tripEncodedPolyline];
		
		CLLocationCoordinate2D* pointArr = malloc(sizeof(CLLocationCoordinate2D) * points.count);
		for (int i=0; i<points.count;i++) {
			CLLocation * location = [points objectAtIndex:i];
			CLLocationCoordinate2D p = location.coordinate;
			pointArr[i] = p;
		}
		
		_routePolyline = [[MKPolyline polylineWithCoordinates:pointArr count:points.count] retain];
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

