//
//  OBAArrivalAndDepartureSectionBuilder.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OBAKit/OBAKit.h>
#import "OBAClassicDepartureRow.h"

@interface OBAArrivalAndDepartureSectionBuilder : NSObject
+ (OBAClassicDepartureRow *)createDepartureRow:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;

@end
