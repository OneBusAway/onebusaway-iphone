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

+(OBADiversionViewController*) loadFromNibWithAppContext:(OBAApplicationContext*)context {
	NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBADiversionViewController" owner:context options:nil];
	OBADiversionViewController* controller = [wired objectAtIndex:0];
	return controller;
}

- (void)dealloc {
	[_polyline release];
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
	
	_polyline = [[MKPolyline polylineWithCoordinates:pointArr count:points.count] retain];
	MKMapView * mv = [self mapView];
	[mv addOverlay:_polyline];
	
	if( ! [bounds empty] ) {
		[mv setRegion:bounds.region];
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
	
	if(overlay == _polyline)
	{
		//if we have not yet created an overlay view for this overlay, create it now.
		if(_polylineView == nil)
		{
			_polylineView = [[MKPolylineView alloc] initWithPolyline:_polyline];
			_polylineView.fillColor = [UIColor redColor];
			_polylineView.strokeColor = [UIColor redColor];
			_polylineView.lineWidth = 5;
		}
		
		overlayView = _polylineView;
	}
	
	return overlayView;	
}


@end

@implementation OBADiversionViewController (Private)

- (MKMapView*) mapView {
	return (MKMapView*) self.view;			
}

@end

