//
//  OBADepartureRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"
#import <OBAKit/OBAKit.h>

@interface OBADepartureRow : OBABaseRow
@property(nonatomic,copy) NSString *destination;
@property(nonatomic,copy) NSDate *departsAt;
@property(nonatomic,copy) NSString *statusText;
@property(nonatomic,assign) OBADepartureStatus departureStatus;

- (double)minutesUntilDeparture;
- (NSString *)formattedMinutesUntilNextDeparture;

- (NSString *)formattedNextDepartureTime;

- (instancetype)initWithAction:(void (^)(OBABaseRow *row))action NS_UNAVAILABLE;
- (instancetype)initWithDestination:(NSString*)destination departsAt:(NSDate*)departsAt statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus action:(void(^)(OBABaseRow *row))action NS_DESIGNATED_INITIALIZER;
@end
