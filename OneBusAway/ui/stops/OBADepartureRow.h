//
//  OBADepartureRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 2/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"
#import "OBAUpcomingDeparture.h"
@import OBAKit;

NS_ASSUME_NONNULL_BEGIN

@interface OBADepartureRow : OBABaseRow
@property(nonatomic,copy,nullable) NSString *destination;
@property(nonatomic,copy,nullable) NSArray<OBAUpcomingDeparture*> *upcomingDepartures;
@property(nonatomic,copy) NSString *statusText;
@property(nonatomic,copy) NSString *routeName;
@property(nonatomic,copy,nullable) void (^toggleBookmarkAction)();
@property(nonatomic,copy,nullable) void (^shareAction)();
@property(nonatomic,assign) BOOL bookmarkExists;
@end

NS_ASSUME_NONNULL_END
