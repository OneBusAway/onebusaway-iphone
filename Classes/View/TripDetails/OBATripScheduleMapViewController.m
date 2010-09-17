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


@interface OBATripScheduleMapViewController (Private)

- (MKMapView*) mapView;

- (id<MKAnnotation>) createTripContinuationAnnotation:(OBATripV2*)trip isNextTrip:(BOOL)isNextTrip stopTimes:(NSArray*)stopTimes;

- (NSInteger) getXOffsetForStop:(OBAStopV2*)stop defaultValue:(NSInteger)defaultXOffset;
- (NSInteger) getYOffsetForStop:(OBAStopV2*)stop defaultValue:(NSInteger)defaultYOffset;

@end


@implementation OBATripScheduleMapViewController

@synthesize appContext;
@synthesize tripDetails;
@synthesize currentStopId;

+(OBATripScheduleMapViewController*) loadFromNibWithAppContext:(OBAApplicationContext*)context {
	NSArray* wired = [[NSBundle mainBundle] loadNibNamed:@"OBATripScheduleMapViewController" owner:context options:nil];
	OBATripScheduleMapViewController* controller = [wired objectAtIndex:0];
	return controller;
}

- (void)dealloc {
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
	
	OBATripScheduleV2 * sched = self.tripDetails.schedule;
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
}

- (void) showList:(id)source {
	OBATripScheduleListViewController * vc = [[OBATripScheduleListViewController alloc] initWithApplicationContext:self.appContext tripDetails:self.tripDetails];
	[vc setCurrentStopId:self.currentStopId];
	[self.navigationController replaceViewController:vc animated:TRUE];
	[vc release];
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	if( [annotation isKindOfClass:[OBATripStopTimeMapAnnotation class]] ) {
		
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
		OBATripStatusV2 * status = self.tripDetails.status;
		OBATripDetailsViewController * vc = [[OBATripDetailsViewController alloc] initWithApplicationContext:self.appContext tripId:an.tripId serviceDate:status.serviceDate];
		[self.navigationController pushViewController:vc animated:TRUE];
		[vc release];
		
	}
}


@end

@implementation OBATripScheduleMapViewController (Private)

- (MKMapView*) mapView {
	return (MKMapView*) self.view;			
}

- (id<MKAnnotation>) createTripContinuationAnnotation:(OBATripV2*)trip isNextTrip:(BOOL)isNextTrip stopTimes:(NSArray*)stopTimes {
	
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
	
	return [[[OBATripContinuationMapAnnotation alloc] initWithTitle:tripTitle tripId:trip.tripId location:p] autorelease];
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

