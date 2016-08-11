//
//  OBAClassicDepartureRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/6/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBADepartureRow.h"

@interface OBAClassicDepartureRow : OBADepartureRow
@property(nonatomic,copy) NSString *routeName;

- (instancetype)initWithDestination:(NSString*)destination departsAt:(NSDate*)departsAt statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus action:(void(^)(OBABaseRow *row))action NS_UNAVAILABLE;

- (instancetype)initWithRouteName:(NSString*)routeName destination:(NSString*)destination departsAt:(NSDate*)departsAt statusText:(NSString*)statusText departureStatus:(OBADepartureStatus)departureStatus action:(void(^)(OBABaseRow *row))action NS_DESIGNATED_INITIALIZER;
@end
