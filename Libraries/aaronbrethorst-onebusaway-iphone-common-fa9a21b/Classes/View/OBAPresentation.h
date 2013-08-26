#import "OBAApplicationDelegate.h"
#import "OBAArrivalAndDepartureV2.h"
#import "OBATripV2.h"
#import "OBATransitLegV2.h"


@interface OBAPresentation : NSObject {
    
}

+ (NSString*) getRouteShortNameForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;

+ (NSString*) getTripHeadsignForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;

+ (NSString*) getTripHeadsignForTransitLeg:(OBATransitLegV2*)transitLeg;

+ (NSString*) getTripHeadsignForTrip:(OBATripV2*)trip;

+ (NSString*) getRouteShortNameForTransitLeg:(OBATransitLegV2*)transitLeg;

+ (NSString*) getRouteShortNameForTrip:(OBATripV2*)trip;

+ (NSString*) getRouteShortNameForRoute:(OBARouteV2*)route;

+ (NSString*) getRouteLongNameForRoute:(OBARouteV2*)route;

+ (UITableViewCell*) tableViewCellForUnreadServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts tableView:(UITableView*)tableView;

+ (UITableViewCell*) tableViewCellForServiceAlerts:(OBAServiceAlertsModel*)serviceAlerts tableView:(UITableView*)tableView;

+ (float) computeStopsForRouteAnnotationScaleFactor:(MKCoordinateRegion)region;

+ (void)showSituations:(NSArray*)situations withappDelegate:(OBAApplicationDelegate*)appDelegate navigationController:(UINavigationController*)navController args:(NSDictionary*)args;

@end
