#import "OBAPresentation.h"
#import "OBASituationsViewController.h"
#import "OBASituationViewController.h"
#import "OBAUITableViewCell.h"
#import "OBASphericalGeometryLibrary.h"
#import "UIDeviceExtensions.h"


static const float kStopForRouteAnnotationMinScale = 0.1;
static const float kStopForRouteAnnotationMaxScaleDistance = 1500;
static const float kStopForRouteAnnotationMinScaleDistance = 8000;


@implementation OBAPresentation

+ (NSString*) getRouteShortNameForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
	NSString * name = arrivalAndDeparture.routeShortName;
	if( name )
		return name;
	return [self getRouteShortNameForRoute:arrivalAndDeparture.route];
}

+ (NSString*) getTripHeadsignForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture {
	NSString * name = arrivalAndDeparture.tripHeadsign;
	if( name )
		return name;
	return [self getTripHeadsignForTrip:arrivalAndDeparture.trip];
}

+ (NSString*) getTripHeadsignForTrip:(OBATripV2*)trip {
	NSString * name = trip.tripHeadsign;
	if( name )
		return name;
	name = [self getRouteLongNameForRoute:trip.route];
	if( name )
		return name;
	return @"Headed somewhere...";
}

+ (NSString*) getRouteShortNameForRoute:(OBARouteV2*)route {
	NSString * name = route.shortName;
	if( name )
		return name;
	return route.longName;	
}

+ (NSString*) getRouteLongNameForRoute:(OBARouteV2*)route {
	return route.longName;
}


+ (UITableViewCell*) tableViewCellForUnreadServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts tableView:(UITableView*)tableView {
	
	static NSString *cellId = @"UnreadServiceAlertsCell";
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:cellId];
	cell.textLabel.text = [NSString stringWithFormat:@"Service alerts: %d unread",serviceAlerts.unreadCount];
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	NSString * maxSeverity = serviceAlerts.unreadMaxSeverity;
	
	if( maxSeverity && [maxSeverity isEqualToString:@"noImpact"] )
		cell.imageView.image = [UIImage imageNamed:@"Alert-Info"];
	else
		cell.imageView.image = [UIImage imageNamed:@"Alert"];
	
	return cell;	
}

+ (UITableViewCell*) tableViewCellForServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts tableView:(UITableView*)tableView {
	
	static NSString *cellId = @"ServiceAlertsCell";
	
	UITableViewCell * cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:cellId];
	
	if( serviceAlerts.totalCount == 0 )
		cell.textLabel.text = @"Service Alerts";
	else
		cell.textLabel.text = [NSString stringWithFormat:@"Service Alerts: %d total", serviceAlerts.totalCount];						    
	
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	if( serviceAlerts.totalCount == 0 ) {
		cell.imageView.image = nil;
	}
	else {
		if( serviceAlerts.unreadCount > 0 ) {
			
			NSString * maxSeverity = serviceAlerts.unreadMaxSeverity;	
			
			if( maxSeverity && [maxSeverity isEqualToString:@"noImpact"] )
				cell.imageView.image = [UIImage imageNamed:@"Alert-Info"];
			else
				cell.imageView.image = [UIImage imageNamed:@"Alert"];
		}
		else {
			
			NSString * maxSeverity = serviceAlerts.maxSeverity;	
			
			if( maxSeverity && [maxSeverity isEqualToString:@"noImpact"] )
				cell.imageView.image = [UIImage imageNamed:@"Alert-Info-Grayscale"];
			else
				cell.imageView.image = [UIImage imageNamed:@"AlertGrayscale"];
		}
	}
	
	return cell;	
}	

+ (void) showSituations:(NSArray*)situations withAppContext:(OBAApplicationContext*)appContext navigationController:(UINavigationController*)navigationController args:(NSDictionary*)args {
	if( [situations count] == 1 ) {
		OBASituationV2 * situation = [situations objectAtIndex:0];
		OBASituationViewController * vc = [[OBASituationViewController alloc] initWithApplicationContext:appContext situation:situation];
		vc.args = args;
		[navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
	else {
		OBASituationsViewController * vc = [[OBASituationsViewController alloc] initWithApplicationContext:appContext situations:situations];
		vc.args = args;
		[navigationController pushViewController:vc animated:TRUE];
		[vc release];
	}
}

+ (float) computeStopsForRouteAnnotationScaleFactor:(MKCoordinateRegion)region {
	
	/**
	 * On devices that don't support MKPolyline, we don't scale the stops
	 * because we won't have a corresponding polyline showing the route path
	 */
	if( ! [[UIDevice currentDevice] isMKPolylineSupportedSafe] )
		return 1.0;
	
	MKCoordinateSpan span = region.span;
	CLLocationCoordinate2D center = region.center;
	
	double lat1 = center.latitude;
	double lon1 = center.longitude - span.longitudeDelta / 2;
	
	double lat2 = center.latitude;
	double lon2 = center.longitude + span.longitudeDelta / 2;
	
	CLLocation * a = [[CLLocation alloc] initWithLatitude:lat1 longitude:lon1];
	CLLocation * b = [[CLLocation alloc] initWithLatitude:lat2 longitude:lon2];
	
	double d = [a distanceFromLocationSafe:b];
	
	[a release];
	[b release];
	
	if( d <= kStopForRouteAnnotationMaxScaleDistance ) { 
		return 1.0;
	}
	else if( d < kStopForRouteAnnotationMinScaleDistance ) {
		float kStopForRouteAnnotationScaleSlope = (1.0-kStopForRouteAnnotationMinScale) / (kStopForRouteAnnotationMaxScaleDistance-kStopForRouteAnnotationMinScaleDistance);
		float kStopForRouteAnnotationScaleOffset = 1.0 - kStopForRouteAnnotationScaleSlope * kStopForRouteAnnotationMaxScaleDistance;

		double scale = kStopForRouteAnnotationScaleSlope * d + kStopForRouteAnnotationScaleOffset;
		return scale;
	}
	else {
		return kStopForRouteAnnotationMinScale;
	}
}

@end