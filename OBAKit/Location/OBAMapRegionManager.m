/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <OBAKit/OBAMapRegionManager.h>
#import <OBAKit/OBASphericalGeometryLibrary.h>
#import <OBAKit/OBALogging.h>

static const double kMinRegionDeltaToDetectUserDrag = 50;
static const double kRegionChangeRequestsTimeToLive = 3.0;

@interface OBAMapRegionManager ()
@property(nonatomic,strong) NSHashTable *delegates;
@property BOOL currentlyChangingRegion;
@property NSUInteger regionChangeRequestCount;
@property(strong) OBARegionChangeRequest *pendingRegionChangeRequest;
@property(strong) NSMutableArray *appliedRegionChangeRequests;
@end

@implementation OBAMapRegionManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _delegates = [NSHashTable weakObjectsHashTable];
        _lastRegionChangeWasProgrammatic = NO;
        _currentlyChangingRegion = NO;
        _pendingRegionChangeRequest = nil;
        _appliedRegionChangeRequests = [[NSMutableArray alloc] init];
        _lastRegionChangeWasProgrammatic = YES;
    }
    return self;
}

#pragma mark - Delegate

- (void)addDelegate:(id<OBAMapRegionDelegate>)delegate {
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<OBAMapRegionDelegate>)delegate {
    [self.delegates removeObject:delegate];
}

- (void)callDelegatesWithUpdatedRegion:(MKCoordinateRegion)region animated:(BOOL)animated {
    for (id<OBAMapRegionDelegate> delegate in self.delegates) {
        [delegate mapRegionManager:self setRegion:region animated:animated];
    }
}

#pragma mark - Public

- (void)setRegion:(MKCoordinateRegion)region {
    [self setMapRegion:region requestType:OBARegionChangeRequestTypeProgrammatic];
}

- (void)setRegion:(MKCoordinateRegion)region changeWasProgrammatic:(BOOL)changeWasProgrammatic {
    [self setMapRegion:region requestType:(changeWasProgrammatic ? OBARegionChangeRequestTypeProgrammatic : OBARegionChangeRequestTypeUser)];
}

- (void)setRegionFromNavigationTarget:(OBANavigationTarget*)navigationTarget {
    NSDictionary *parameters = navigationTarget.parameters;
    NSData *data = parameters[OBANavigationTargetSearchKey];
    MKCoordinateRegion region;
    [data getBytes:&region length:sizeof(MKCoordinateRegion)];
    [self setRegion:region changeWasProgrammatic:NO];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    self.currentlyChangingRegion = YES;
}

- (BOOL)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    self.currentlyChangingRegion = NO;
    
    /**
     * We need to figure out if this region change came from the user dragging the map                                                                                                                                         
     * or from an actual programmatic request we instigated.  The easiest way to tell is to                                                                                                                                                
     * keep a list of all our applied programmatic region changes and compare them against
     * the actual map region change.  When the actual map region change doesn't match any
     * of our applied requests, we assume it must have been from a user zoom or pan.
     */
    MKCoordinateRegion region = mapView.region;
    OBARegionChangeRequestType type = OBARegionChangeRequestTypeUser;

    [self callDelegatesWithUpdatedRegion:region animated:YES];
    
    DDLogVerbose(@"=== regionDidChangeAnimated: requests=%lu",(unsigned long)[self.appliedRegionChangeRequests count]);
    DDLogVerbose(@"region=%@", [OBASphericalGeometryLibrary regionAsString:region]);

    OBARegionChangeRequest *request = [self getBestRegionChangeRequestForRegion:region];
    if (request) {
        double score = [request compareRegion:region];
        BOOL oldRegionContainsNewRegion = [OBASphericalGeometryLibrary isRegion:region containedBy:request.region];
        BOOL newRegionContainsOldRegion = [OBASphericalGeometryLibrary isRegion:request.region containedBy:region];

        if (score < kMinRegionDeltaToDetectUserDrag && !oldRegionContainsNewRegion && !newRegionContainsOldRegion) {
            type = request.type;
        }

        DDLogVerbose(@"regionDidChangeAnimated: score=%f", score);
        DDLogVerbose(@"subregion=%@", [OBASphericalGeometryLibrary regionAsString:request.region]);
    }

    self.lastRegionChangeWasProgrammatic = (type == OBARegionChangeRequestTypeProgrammatic || ![self treatRegionChangesAsAutomatic]);
    DDLogVerbose(@"regionDidChangeAnimated: setting self.lastRegionChangeWasprogrammatic to %d", self.lastRegionChangeWasProgrammatic);

    BOOL applyingPendingRequest = NO;
    
    if (self.lastRegionChangeWasProgrammatic && self.pendingRegionChangeRequest) {
        DDLogVerbose(@"applying pending request");
        [self setMapRegionWithRequest:self.pendingRegionChangeRequest];
        applyingPendingRequest = YES;
    }
    
    self.pendingRegionChangeRequest = nil;

    return applyingPendingRequest;
}

- (BOOL)treatRegionChangesAsAutomatic {
    return self.regionChangeRequestCount > 1;
}

#pragma mark - Private Methods

- (void)setMapRegion:(MKCoordinateRegion)region requestType:(OBARegionChangeRequestType)requestType {
    OBARegionChangeRequest * request = [[OBARegionChangeRequest alloc] initWithRegion:region type:requestType];
    [self setMapRegionWithRequest:request];
}

- (void)setMapRegionWithRequest:(OBARegionChangeRequest*)request {

    @synchronized(self) {
        DDLogVerbose(@"setMapRegion: requestType=%ld region=%@",(long)request.type,[OBASphericalGeometryLibrary regionAsString:request.region]);

        /**
         * If we are currently in the process of changing the map region, we save the region change request as pending.
         * Otherwise, we apply the region change.
         */
        if (self.currentlyChangingRegion) {
            DDLogVerbose(@"saving pending request");
            self.pendingRegionChangeRequest = request;
        }
        else {
            [self.appliedRegionChangeRequests addObject:request];
            [self callDelegatesWithUpdatedRegion:request.region animated:[self treatRegionChangesAsAutomatic]];
        }

        /**
         * firstRegionChangeRequested makes sure that the map view zooms to your current location before any requests have been made
         * map view will show current location on app startup
         */
        self.regionChangeRequestCount += 1;
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
