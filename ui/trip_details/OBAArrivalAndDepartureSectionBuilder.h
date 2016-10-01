//
//  OBAArrivalAndDepartureSectionBuilder.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OBAKit/OBAKit.h>
#import "OBADepartureRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalAndDepartureSectionBuilder : NSObject
+ (nullable OBADepartureRow *)createDepartureRow:(NSArray<OBAArrivalAndDepartureV2*>*)arrivalAndDepartures;
@end

NS_ASSUME_NONNULL_END
