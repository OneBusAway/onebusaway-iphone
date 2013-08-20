//
//  OBARegionListViewController.h
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/15/13.
//
//

#import "OBAApplicationDelegate.h"
#import "OBARequestDrivenTableViewController.h"

@interface OBARegionListViewController : OBARequestDrivenTableViewController<OBALocationManagerDelegate> {
    NSMutableArray * _regions;    
    CLLocation * _mostRecentLocation;
    BOOL _hideFutureNetworkErrors;
    BOOL _locationTimedOut;
    NSTimer *_locationTimer;
}

@property (nonatomic) OBARegionV2 *nearbyRegion;
@property (nonatomic) NSIndexPath *checkedItem;

- (id) initWithApplicationContext:(OBAApplicationDelegate*)appContext;
- (void) sortRegionsByLocation;
- (void) sortRegionsByName;
- (void) timeOutLocation:(NSTimer*)theTimer;
- (void) showLocationServicesAlert;

@end
