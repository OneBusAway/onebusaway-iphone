//
//  OBARegionListViewController.h
//  org.onebusaway.iphone
//
//  Created by chaya3 on 5/15/13.
//
//

#import "OBAApplicationDelegate.h"
#import "OBARequestDrivenTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBARegionListViewController : OBARequestDrivenTableViewController<OBALocationManagerDelegate> 

@property(nonatomic,strong,nullable) OBARegionV2 *nearbyRegion;
@property(nonatomic,strong,nullable) NSIndexPath *checkedItem;

- (id)initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate;
- (void)sortRegionsByLocation;
- (void)sortRegionsByName;
- (void)timeOutLocation:(NSTimer*)theTimer;
- (void)showLocationServicesAlert;

@end

NS_ASSUME_NONNULL_END