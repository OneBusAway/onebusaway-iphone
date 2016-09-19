//
//  OBAInfoViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 9/17/12.
//
//

#import <UIKit/UIKit.h>
#import <OBAKit/OBAKit.h>
#import "OBAStaticTableViewController.h"
#import "OBANavigationTargetAware.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAInfoViewController : OBAStaticTableViewController<OBANavigationTargetAware>
@property(nonatomic,strong) OBAModelDAO *modelDAO;
- (void)openAgencies;
@end

NS_ASSUME_NONNULL_END
