#import "OBAMapRegionManager.h"
#import "OBASphericalGeometryLibrary.h"
#import "OBALogger.h"


static const double kMinRegionDeltaToDetectUserDrag = 50;
static const double kRegionChangeRequestsTimeToLive = 3.0;

@interface OBAMapRegionManager ()
@property(strong) MKMapView *mapView;
@property BOOL currentlyChangingRegion;
@property BOOL firstRegionChangeRequested;
@property(strong) OBARegionChangeRequest *pendingRegionChangeRequest;
@property(strong) NSMutableArray *appliedRegionChangeRequests;

- (void)setMapRegion:(MKCoordinateRegion)region requestType:(OBARegionChangeRequestType)requestType;
- (void)setMapRegionWithRequest:(OBARegionChangeRequest*)request;
- (OBARegionChangeRequest*) getBestRegionChangeRequestForRegion:(MKCoordinateRegion)region;
@end


@implementation OBAMapRegionManager

- (id) initWithMapView:(MKMapView*)mapView {
    self = [super init];
    if (self) {
        self.mapView = mapView;
        self.lastRegionChangeWasProgramatic = NO;
        self.currentlyChangingRegion = NO;
        self.firstRegionChangeRequested = NO;
        self.pendingRegionChangeRequest = nil;
        self.appliedRegionChangeRequests = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) setRegion:(MKCoordinateRegion)region {
    [self setMapRegion:region requestType:OBARegionChangeRequestTypeProgramatic];
}

- (void) setRegion:(MKCoordinateRegion)region changeWasProgramatic:(BOOL)changeWasProgramatic {
    [self setMapRegion:region requestType:(changeWasProgramatic ? OBARegionChangeRequestTypeProgramatic : OBARegionChangeRequestTypeUser)];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    self.currentlyChangingRegion = YES;
}

- (BOOL)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    
    self.currentlyChangingRegion = NO;
    
    /**
     * We need to figure out if this region change came from the user dragging the map                                                                                                                                         
     * or from an actual programatic request we instigated.  The easiest way to tell is to                                                                                                                                                
     * keep a list of all our applied programatic region changes and compare them against
     * the actual map region change.  When the actual map region change doesn't match any
     * of our applied requests, we assume it must have been from a user zoom or pan.
     */
    MKCoordinateRegion region = self.mapView.region;
    OBARegionChangeRequestType type = OBARegionChangeRequestTypeUser;
    
    //OBALogDebug(@"=== regionDidChangeAnimated: requests=%d",[self.appliedRegionChangeRequests count]);
    //OBALogDebug(@"region=%@", [OBASphericalGeometryLibrary regionAsString:region]);
    
    OBARegionChangeRequest * request = [self getBestRegionChangeRequestForRegion:region];
    if( request ) {
        double score = [request compareRegion:region];
        BOOL oldRegionContainsNewRegion = [OBASphericalGeometryLibrary isRegion:region containedBy:request.region];
        BOOL newRegionContainsOldRegion = [OBASphericalGeometryLibrary isRegion:request.region containedBy:region];
        //OBALogDebug(@"regionDidChangeAnimated: score=%f", score);
        //OBALogDebug(@"subregion=%@", [OBASphericalGeometryLibrary regionAsString:request.region]);
        if( score < kMinRegionDeltaToDetectUserDrag && !oldRegionContainsNewRegion && !newRegionContainsOldRegion)
            type = request.type;
    }
    
    self.lastRegionChangeWasProgramatic = (type == OBARegionChangeRequestTypeProgramatic || !self.firstRegionChangeRequested);
    //OBALogDebug(@"regionDidChangeAnimated: setting self.lastRegionChangeWasProgramatic to %d", self.lastRegionChangeWasProgramatic);
    
    BOOL applyingPendingRequest = NO;
    
    if( self.lastRegionChangeWasProgramatic && self.pendingRegionChangeRequest ) {
        //OBALogDebug(@"applying pending reqest");
        [self setMapRegionWithRequest:self.pendingRegionChangeRequest];
        applyingPendingRequest = YES;
    }
    
    self.pendingRegionChangeRequest = nil;

    return applyingPendingRequest;
}

#pragma mark - Private Methods


- (void) setMapRegion:(MKCoordinateRegion)region requestType:(OBARegionChangeRequestType)requestType {

    OBARegionChangeRequest * request = [[OBARegionChangeRequest alloc] initWithRegion:region type:requestType];
    [self setMapRegionWithRequest:request];
}

- (void) setMapRegionWithRequest:(OBARegionChangeRequest*)request {

    @synchronized(self) {
        //OBALogDebug(@"setMapRegion: requestType=%d region=%@",request.type,[OBASphericalGeometryLibrary regionAsString:request.region]);

        /**
         * If we are currently in the process of changing the map region, we save the region change request as pending.
         * Otherwise, we apply the region change.
         */
        if ( self.currentlyChangingRegion ) {
            //OBALogDebug(@"saving pending request");
            self.pendingRegionChangeRequest = request;
        }
        else {
            [self.appliedRegionChangeRequests addObject:request];
            [self.mapView setRegion:request.region animated:YES];
        }

        /**
         * firstRegionChangeRequested makes sure that the map view zooms to your current location before any requests have been made
         * map view will show current location on app startup
         */
        self.firstRegionChangeRequested = YES;
    }
}

- (OBARegionChangeRequest*) getBestRegionChangeRequestForRegion:(MKCoordinateRegion)region {

    NSMutableArray * requests = [[NSMutableArray alloc] init];
    OBARegionChangeRequest * bestRequest = nil;
    double bestScore = 0;

    NSDate * now = [NSDate date];

    for( OBARegionChangeRequest * request in  self.appliedRegionChangeRequests ) {

        NSTimeInterval interval = [now timeIntervalSinceDate:request.timestamp];

        if( interval <= kRegionChangeRequestsTimeToLive ) {
            [requests addObject:request];
            double score = [request compareRegion:region];
            if( bestRequest == nil || score < bestScore)  {
                bestRequest = request;
                bestScore = score;
            }
        }
    }

    self.appliedRegionChangeRequests = requests;


    return bestRequest;
}

@end
