//
//  OBAUpcomingDeparture.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/13/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBADepartureStatus.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAUpcomingDeparture : NSObject<NSCopying>
@property(nonatomic,assign) OBAArrivalDepartureState arrivalDepartureState;
@property(nonatomic,copy) NSDate *departureDate;
@property(nonatomic,assign) OBADepartureStatus departureStatus;

- (instancetype)initWithDepartureDate:(NSDate*)departureDate departureStatus:(OBADepartureStatus)departureStatus arrivalDepartureState:(OBAArrivalDepartureState)arrivalDepartureState;

+ (NSArray<OBAUpcomingDeparture*>*)upcomingDeparturesFromArrivalsAndDepartures:(NSArray<OBAArrivalAndDepartureV2*>*)matchingDepartures;
@end

NS_ASSUME_NONNULL_END
