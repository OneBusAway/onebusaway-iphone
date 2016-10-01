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
@property(nonatomic,copy) NSArray<NSDate*> *upcomingDepartures;
@property(nonatomic,copy) NSString *statusText;
@property(nonatomic,assign) OBADepartureStatus departureStatus;
@property(nonatomic,copy) NSString *routeName;

- (nullable NSString *)formattedNextDepartureTime;
@end

NS_ASSUME_NONNULL_END
