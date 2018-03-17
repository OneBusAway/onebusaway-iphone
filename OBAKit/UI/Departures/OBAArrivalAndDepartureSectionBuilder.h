//
//  OBAArrivalAndDepartureSectionBuilder.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBAModelDAO.h>
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBADepartureRow.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAArrivalAndDepartureSectionBuilder : NSObject
- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO;
- (OBADepartureRow*)createDepartureRowForStop:(OBAArrivalAndDepartureV2*)dep;
@end

NS_ASSUME_NONNULL_END
