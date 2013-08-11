//
//  OBARegionHelper.h
//  org.onebusaway.iphone
//
//  Created by Sebastian Kießling on 11.08.13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBAModelService.h"
#import "OBARegionV2.h"

@interface OBARegionHelper : NSObject <OBAModelServiceDelegate,OBALocationManagerDelegate>


- (void) updateNearestRegion;
@end
