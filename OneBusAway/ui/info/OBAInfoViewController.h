//
//  OBAInfoViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/17/12.
//
//

@import UIKit;
@import OBAKit;
#import "OBAStaticTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAInfoViewController : OBAStaticTableViewController<OBANavigationTargetAware>
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) PrivacyBroker *privacyBroker;
@property(nonatomic,strong) OBALocationManager *locationManager;

- (void)openAgencies;
@end

NS_ASSUME_NONNULL_END
