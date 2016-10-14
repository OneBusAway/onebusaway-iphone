//
//  OBAUpcomingDeparture.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import OBAKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBAUpcomingDeparture : NSObject<NSCopying>
@property(nonatomic,copy) NSDate *departureDate;
@property(nonatomic,assign) OBADepartureStatus departureStatus;

- (instancetype)initWithDepartureDate:(NSDate*)departureDate departureStatus:(OBADepartureStatus)departureStatus;
@end

NS_ASSUME_NONNULL_END
