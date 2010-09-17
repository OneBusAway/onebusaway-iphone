//
//  OBANearbyTripsController.m
//  org.onebusaway.iphone
//
//  Created by Brian Ferris on 10/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OBANearbyTripsController.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBALogger.h"
#import "OBATripStatus.h"


static const double kSearchRadius = 800;
static const int kTimeInterval = 15;
@interface OBANearbyTripsController (Private)

- (void) refresh;

@end


@implementation OBANearbyTripsController

@synthesize delegate = _delegate;

- (id) initWithApplicationContext:(OBAApplicationContext*)appContext {
	if( self = [super init] ) {
		_appContext = [appContext retain];
		_jsonDataSource = [[OBAJsonDataSource alloc] initWithConfig:appContext.obaDataSourceConfig];
	}
	return self;
}

- (void) dealloc {
	[self stop];
	[_timer release];	
	[_jsonDataSource release];
	[_appContext release];
	
	[_delegate release];
	_delegate = nil;
	
	[super dealloc];
}

- (void) start {
	[self refresh];
	if( ! _timer ) {
		_timer = [NSTimer scheduledTimerWithTimeInterval:kTimeInterval target:self selector:@selector(refresh) userInfo:nil repeats:TRUE];
		[_timer retain];
	}	
	
}

- (void) stop {
	if( _timer ) {
		[_timer invalidate];
		[_timer release];
		_timer = nil;
	}
	[_jsonDataSource cancelOpenConnections];
}

#pragma mark OBDataSourceDelegate Methods

- (void)connectionDidFinishLoading:(id<OBADataSourceConnection>)connection withObject:(id)obj context:(id)context {

	NSNumber * code = [obj valueForKey:@"code"];
	
	if( code == nil || [code intValue] != 200 ) {
		NSLog(@"bad...");
		return;
	}
	
	NSDictionary * data = [obj valueForKey:@"data"];
	NSArray * values = [data objectForKey:@"list"];
	
	NSError * error = nil;
	OBAModelFactory * factory = _appContext.modelFactory;
	NSArray * tripStatusElements = [factory getTripStatusElementsFromJSONArray:values error:&error];
	
	if( error ) {
		if( _delegate && [_delegate respondsToSelector:@selector(handleNearbyTripsControllerError:)] )
			[_delegate handleNearbyTripsControllerError:error];
		return;
	}
	
	OBAActivityListeners * acitivtyListeners = _appContext.activityListeners;
	[acitivtyListeners nearbyTrips:tripStatusElements];
	
	[_delegate handleNearbyTripsControllerUpdate:tripStatusElements];
}

- (void)connectionDidFail:(id<OBADataSourceConnection>)connection withError:(NSError *)error context:(id)context {
	
}

@end


@implementation OBANearbyTripsController (Private)

- (void) refresh {
	OBALocationManager * locationManager = _appContext.locationManager;
	
	CLLocation * location = locationManager.currentLocation;
	if( location ) {
		MKCoordinateRegion region = [OBASphericalGeometryLibrary createRegionWithCenter:location.coordinate latRadius:kSearchRadius lonRadius:kSearchRadius];
		
		CLLocationCoordinate2D coord = region.center;
		MKCoordinateSpan span = region.span;
		
		NSString *args = [NSString stringWithFormat:@"lat=%f&lon=%f&latSpan=%f&lonSpan=%f", coord.latitude, coord.longitude,span.latitudeDelta,span.longitudeDelta];
		[_jsonDataSource requestWithPath:@"/api/where/trips-for-location.json" withArgs:args withDelegate:self context:nil];	
	}
}


@end

