//
//  OBADepartureRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"
#import <OBAKit/OBAKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBADepartureRow : OBABaseRow
@property(nonatomic,copy,nullable) NSString *destination;
@property(nonatomic,copy) NSDate *departsAt;
@property(nonatomic,copy) NSString *statusText;
@property(nonatomic,assign) OBADepartureStatus departureStatus;

- (double)minutesUntilDeparture;
- (NSString *)formattedMinutesUntilNextDeparture;

- (NSString *)formattedNextDepartureTime;

- (instancetype)initWithAction:(void (^ _Nullable)(OBABaseRow *row))action NS_UNAVAILABLE;
- (instancetype)initWithDestination:(nullable NSString*)destination departsAt:(NSDate*)departsAt statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus action:(void(^)(OBABaseRow *row))action NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END
