//
//  OBABookmarkRouteDisambiguationViewController.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/31/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import UIKit;
#import "OBAStaticTableViewController.h"

@class OBAArrivalsAndDeparturesForStopV2;
@class OBARegionV2;
@class OBAModelDAO;
@class OBARouteFilter;

NS_ASSUME_NONNULL_BEGIN

@interface OBABookmarkRouteDisambiguationViewController : OBAStaticTableViewController
@property(nonatomic,strong) OBARegionV2 *region;
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) OBARouteFilter *routeFilter;

- (instancetype)initWithArrivalsAndDeparturesForStop:(OBAArrivalsAndDeparturesForStopV2*)arrivalsAndDepartures;
@end

NS_ASSUME_NONNULL_END
