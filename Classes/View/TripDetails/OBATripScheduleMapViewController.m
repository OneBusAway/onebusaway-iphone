#import "OBATripScheduleMapViewController.h"
#import "OBATripScheduleListViewController.h"
#import "OBAUIKit.h"
#import "OBAStopV2.h"
#import "OBATripStopTimeV2.h"
#import "OBAStopIconFactory.h"
#import "OBATripStopTimeMapAnnotation.h"
#import "OBACoordinateBounds.h"
#import "OBAStopViewController.h"


@interface OBATripScheduleMapViewController (Private)

- (MKMapView*) mapView;

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
	MKMapView * mapView = [self mapView];
	
	NSMutableArray * annotations = [[NSMutableArray alloc] init];
	
	OBACoordinateBounds * bounds = [[OBACoordinateBounds alloc] init];
	
	for( OBATripStopTimeV2 * stopTime in sched.stopTimes ) {
		
		OBATripStopTimeMapAnnotation * an = [[OBATripStopTimeMapAnnotation alloc] initWithTripDetails:self.tripDetails stopTime:stopTime];
		an.timeFormatter = _timeFormatter;
		[annotations addObject:an];
		[an release];
		
		OBAStopV2 * stop = stopTime.stop;
		[bounds addLat:stop.lat lon:stop.lon];
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
}


@end

@implementation OBATripScheduleMapViewController (Private)

- (MKMapView*) mapView {
	return (MKMapView*) self.view;			
}

@end

