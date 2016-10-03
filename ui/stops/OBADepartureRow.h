//
//  OBADepartureRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"
@import OBAKit;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const OBAClassicDepartureCellReuseIdentifier;

@interface OBADepartureRow : OBABaseRow
@property(nonatomic,copy,nullable) NSString *destination;
@property(nonatomic,copy) NSDate *departsAt;
@property(nonatomic,copy) NSString *statusText;
@property(nonatomic,assign) OBADepartureStatus departureStatus;
@property(nonatomic,copy) NSString *routeName;

- (double)minutesUntilDeparture;
- (NSString *)formattedMinutesUntilNextDeparture;
- (NSString *)formattedNextDepartureTime;
@end

NS_ASSUME_NONNULL_END
