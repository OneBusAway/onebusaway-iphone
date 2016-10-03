//
//  OBAArrivalAndDepartureSectionBuilder.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import OBAKit;
#import "OBADepartureRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalAndDepartureSectionBuilder : NSObject
+ (nullable OBADepartureRow *)createDepartureRow:(OBAArrivalAndDepartureV2*)arrivalAndDeparture;
@end

NS_ASSUME_NONNULL_END
