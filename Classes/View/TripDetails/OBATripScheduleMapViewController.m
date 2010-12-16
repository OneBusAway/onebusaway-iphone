#import "OBATripScheduleMapViewController.h"
#import "OBATripScheduleListViewController.h"
#import "OBAUIKit.h"
#import "OBAStopV2.h"
#import "OBATripStopTimeV2.h"
#import "OBAStopIconFactory.h"
#import "OBATripStopTimeMapAnnotation.h"
#import "OBATripContinuationMapAnnotation.h"
#import "OBACoordinateBounds.h"
#import "OBAStopViewController.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBATripDetailsViewController.h"
#import "OBAPresentation.h"
#import "UIDeviceExtensions.h"


static const NSString * kTripDetailsContext = @"TripDetails";
static const NSString * kShapeContext = @"ShapeContext"	;


@interface OBATripScheduleMapViewController (Private)

- (MKMapView*) mapView;

- (void) handleTripDetails;
- (id<MKAnnotation>) createTripContinuationAnnotation:(OBATripV2*)trip isNextTrip:(BOOL)isNextTrip stopTimes:(NSArray*)stopTimes;

- (NSInteger) getXOffsetForStop:(OBAStopV2*)stop defaultValue:(NSInteger)defaultXOffset;
- (NSInteger) getYOffsetForStop:(OBAStopV2*)stop defaultValue:(NSInteger)defaultYOffset;

@end


@implementation OBATripScheduleMapViewController

@synthesize appContext = _appContext;
@synthesize progressView = _progressView;
@synthesize tripInstance = _tripInstance;
@synthesize tripDetails = _tripDetails;
@synthesize currentStopId = _currentStopId;

+(OBATripScheduleMapViewController*) loadFromNibWithAppContext:(OBAApplicationContext*)context {
	NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBATripScheduleMapViewController" owner:context options:nil];
	OBATripScheduleMapViewController* controller = [wired objectAtIndex:0];
	return controller;
}

- (void)dealloc {
	[_request cancel];
	
	[_appContext release];
	[_tripInstance release];
	[_tripDetails release];
	[_currentStopId release];
	[_request release];
	[_routePolyline release];
	[_routePolylineView release];
	[_progressView release];
	[_timeFormatter release];
    [super dealloc];
}

- (void) viewDidLoad {
	_timeFormatter = [[NSDateFormatter alloc] init];
	[_timeFormatter setDateStyle:NSDateFormatterNoStyle];
	[_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	UIBarButtonItem * backItem = [[UIBarButtonItem alloc] initWithTitle:@"Schedule" style:UIBarButtonItemStyleBordered target:nil action:nil];
	self.navigationItem.backBarButtonItem = backItem;
	[backItem release];	
}

- (void) viewWillAppear:(BOOL)animated {
	
	if( _tripDetails == nil && _tripInstance != nil )
		_request = [[_appContext.modelService requestTripDetailsForTripInstance:_tripInstance withDelegate:self withContext:kTripDetailsContext] retain];
	else
		[self handleTripDetails];
}

- (void) showList:(id)source {
	OBATripScheduleListViewController * vc = [[OBATripScheduleListViewController alloc] initWithApplicationContext:self.appContext tripInstance:_tripInstance];
	vc.tripDetails = self.tripDetails;
	vc.currentStopId = self.currentStopId;
	[self.navigationController replaceViewController:vc animated:TRUE];
	[vc release];
}

#pragma mark OBAModelServiceDelegate

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withObject:(id)obj context:(id)context {
	if( context == kTripDetailsContext ) {
		OBAEntryWithReferencesV2 * entry = obj;
		_tripDetails = [entry.entry retain];
		[self handleTripDetails];
	}
	else if ( context == kShapeContext ) {		
		if( obj ) {
			NSString * polylineString = obj;
			_routePolyline = [[OBASphericalGeometryLibrary decodePolylineStringAsMKPolyline:polylineString] retain];
			[self.mapView addOverlay:_routePolyline];
		}
		[_progressView setMessage:@"Trip Schedule" inProgress:FALSE progress:0];
	}
}

- (void)requestDidFinish:(id<OBAModelServiceRequest>)request withCode:(NSInteger)code context:(id)context {
	if( code == 404 )
		[_progressView setMessage:@"Trip not found" inProgress:FALSE progress:0];
	else
		[_progressView setMessage:@"Unknown error" inProgress:FALSE progress:0];
}

- (void)requestDidFail:(id<OBAModelServiceRequest>)request withError:(NSError *)error context:(id)context {
	OBALogWarningWithError(error, @"Error");
	[_progressView setMessage:@"Error connecting" inProgress:FALSE progress:0];
}

- (void)request:(id<OBAModelServiceRequest>)request withProgress:(float)progress context:(id)context {
	if (progress > 1.0) {
		[_progressView setMessage:@"Downloading..." inProgress:TRUE progress:progress];
	}
    else {
		[_progressView setInProgress:TRUE progress:progress];
	}
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	if( [annotation isKindOfClass:[OBATripStopTimeMapAnnotation class]] ) {
		
		float scale = [OBAPresentation computeStopsForRouteAnnotationScaleFactor:mapView.region];
		float alpha = scale <= 0.11 ? 0.0 : 1.0;
		
		OBATripStopTimeMapAnnotation * an = (OBATripStopTimeMapAnnotation*)annotation;
		static NSString * viewId = @"StopView";
		
		MKAnnotationView * view = [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
		if( view == nil ) {
			view = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId] autorelease];
		}
		view.canShowCallout = TRUE;
		view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		OBAStopIconFactory * stopIconFactory = [[self appContext] stopIconFactory];
		view.image = [stopIconFactory getIconForStop:an.stopTime.stop];
		view.transform = CGAffineTransformMakeScale(scale, scale);
		view.alpha = alpha;
		return view;
	}
	else if ( [annotation isKindOfClass:[OBATripContinuationMapAnnotation class]] ) {
	
		static NSString * viewId = @"TripContinutationView";
		
		MKPinAnnotationView * view = (MKPinAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:viewId];
		if( view == nil ) {
			view = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:viewId] autorelease];
		}
		view.canShowCallout = TRUE;
		view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		return view;
	}
	
	return nil;
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	
	id annotation = view.annotation;
	
	if( [annotation isKindOfClass:[OBATripStopTimeMapAnnotation class] ] ) {		
		OBATripStopTimeMapAnnotation * an = (OBATripStopTimeMapAnnotation*)annotation;
		OBATripStopTimeV2 * stopTime = an.stopTime;
		OBAStopViewController * vc = [[OBAStopViewController alloc] initWithApplicationContext:self.appContext stopId:stopTime.stopId];
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
	else if ( [annotation isKindOfClass:[OBATripContinuationMapAnnotation class]] ) {
		OBATripContinuationMapAnnotation * an = (OBATripContinuationMapAnnotation*)annotation;
		OBATripDetailsViewController * vc = [[OBATripDetailsViewController alloc] initWithApplicationContext:_appContext tripInstance:an.tripInstance];
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];		
	}
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id )overlay {
	
	MKOverlayView* overlayView = nil;
	
	if( overlay == _routePolyline ) {
		
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

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
	
	float scale = [OBAPresentation computeStopsForRouteAnnotationScaleFactor:mapView.region];
	float alpha = scale <= 0.11 ? 0.0 : 1.0;
	NSLog(@"scale=%f alpha=%f", scale, alpha);
	
	CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
	
	for( id<MKAnnotation> annotation in mapView.annotations ) {
		if ([annotation isKindOfClass:[OBATripStopTimeMapAnnotation class]]) {
			MKAnnotationView * view = [mapView viewForAnnotation:annotation];
			view.transform = transform;
			view.alpha = alpha;
		}
	}
}

@end


@implementation OBATripScheduleMapViewController (Private)

- (MKMapView*) mapView {
	return (MKMapView*) self.view;			
}

- (void) handleTripDetails {
	
	[_progressView setMessage:@"Trip Schedule" inProgress:FALSE progress:0];

	OBATripScheduleV2 * sched = _tripDetails.schedule;
	NSArray * stopTimes = sched.stopTimes;
	MKMapView * mapView = [self mapView];
	
	NSMutableArray * annotations = [[NSMutableArray alloc] init];
	
	OBACoordinateBounds * bounds = [[OBACoordinateBounds alloc] init];
	
	for( OBATripStopTimeV2 * stopTime in stopTimes ) {
		
		OBATripStopTimeMapAnnotation * an = [[OBATripStopTimeMapAnnotation alloc] initWithTripDetails:self.tripDetails stopTime:stopTime];
		an.timeFormatter = _timeFormatter;
		[annotations addObject:an];
		[an release];
		
		OBAStopV2 * stop = stopTime.stop;
		[bounds addLat:stop.lat lon:stop.lon];
	}
	
	if( sched.nextTripId && [stopTimes count] > 0 ) {
		id<MKAnnotation> an = [self createTripContinuationAnnotation:sched.nextTrip	isNextTrip:TRUE stopTimes:stopTimes];
		[annotations addObject:an];
	}
	
	if( sched.previousTripId && [stopTimes count] > 0 ) {
		id<MKAnnotation> an = [self createTripContinuationAnnotation:sched.previousTrip	isNextTrip:FALSE stopTimes:stopTimes];
		[annotations addObject:an];
	}
	
	
	[mapView addAnnotations:annotations];
	
	if( ! bounds.empty )
		[mapView setRegion:bounds.region];
	
	OBATripV2 * trip = _tripDetails.trip;
	if( trip && trip.shapeId && [[UIDevice currentDevice] isMKMapViewOverlaysSupportedSafe:[self mapView]]) {
		_request = [[_appContext.modelService requestShapeForId:trip.shapeId withDelegate:self withContext:kShapeContext] retain];
	}
}

- (id<MKAnnotation>) createTripContinuationAnnotation:(OBATripV2*)trip isNextTrip:(BOOL)isNextTrip stopTimes:(NSArray*)stopTimes {
	
	OBATripInstanceRef * tripRef = _tripDetails.tripInstance;
	
	NSString * format = isNextTrip ? @"Coninutes as %@" : @"Starts as %@";
	NSString * tripTitle = [NSString stringWithFormat:format, trip.asLabel];
	NSInteger index = isNextTrip ? ([stopTimes count]-1) : 0;
	OBATripStopTimeV2 * stopTime = [stopTimes objectAtIndex:index];
	OBAStopV2 * stop = stopTime.stop;

	MKCoordinateRegion r = [OBASphericalGeometryLibrary createRegionWithCenter:stop.coordinate latRadius:100 lonRadius:100];
	MKCoordinateSpan span = r.span;
	
	NSInteger x = [self getXOffsetForStop:stop defaultValue:(isNextTrip?1:-1)];
	NSInteger y = [self getYOffsetForStop:stop defaultValue:(isNextTrip?1:-1)];
	
	double lat = (stop.lat + y * span.latitudeDelta/2);
	double lon = (stop.lon + x * span.longitudeDelta/2);
	CLLocationCoordinate2D p = [OBASphericalGeometryLibrary makeCoordinateLat:lat lon:lon];
	
	return [[[OBATripContinuationMapAnnotation alloc] initWithTitle:tripTitle tripInstance:tripRef location:p] autorelease];
}

- (NSInteger) getXOffsetForStop:(OBAStopV2*)stop defaultValue:(NSInteger)defaultXOffset {

	NSString * direction = stop.direction;
	if( ! direction )
		return defaultXOffset;
	
	if( [direction rangeOfString:@"W"].location != NSNotFound )
		return -1 * defaultXOffset;
	else if ( [direction rangeOfString:@"E"].location != NSNotFound )
		return 1 * defaultXOffset;
	return 0;
}

- (NSInteger) getYOffsetForStop:(OBAStopV2*)stop defaultValue:(NSInteger)defaultYOffset {
	
	NSString * direction = stop.direction;
	if( ! direction )
		return defaultYOffset;
	if( [direction rangeOfString:@"S"].location != NSNotFound )
		return -1 * defaultYOffset;
	else if ( [direction rangeOfString:@"N"].location != NSNotFound )
		return 1 * defaultYOffset;
	return 0;
}

@end

