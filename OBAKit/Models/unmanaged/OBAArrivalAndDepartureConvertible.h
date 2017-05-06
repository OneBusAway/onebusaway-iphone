//
//  OBAArrivalAndDepartureConvertible.h
//  OBAKit
//
//  Created by Aaron Brethorst on 1/16/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 Defines the common properties exposed by classes like OBAAlarm and OBATripDeepLink
 that can be used to retrieve an OBAArrivalAndDepartureV2 from the server.
 */
@protocol OBAArrivalAndDepartureConvertible<NSObject, NSCopying>
- (NSString*)stopID;
- (NSString*)tripID;
- (long long)serviceDate;
- (NSString*)vehicleID;
- (NSInteger)stopSequence;
@end

NS_ASSUME_NONNULL_END
