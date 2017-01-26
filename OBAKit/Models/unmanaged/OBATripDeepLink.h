//
//  OBATripDeepLink.h
//  OBAKit
//
//  Created by Aaron Brethorst on 10/30/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBARegionV2.h>
#import <OBAKit/OBAArrivalAndDepartureConvertible.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBATripDeepLink : NSObject<NSCoding,NSCopying,OBAArrivalAndDepartureConvertible>

/**
 The friendly name of this object. Displayed to the user.
 */
@property(nonatomic,copy) NSString *name;

/**
 The region identifier for the region that this deep link object belongs to.
 */
@property(nonatomic,assign) NSInteger regionIdentifier;

/**
 The stop ID for the trip this deep link object represents.
 */
@property(nonatomic,copy) NSString *stopID;

/**
 The trip ID that this deep link object represents.
 */
@property(nonatomic,copy) NSString *tripID;

/**
 The service date for the trip that this deep link object represents.
 */
@property(nonatomic,assign) long long serviceDate;

/**
 The stop sequence for the trip that this deep link object represents.
 */
@property(nonatomic,assign) NSInteger stopSequence;

/**
 Unique identifier for the vehicle that this trip occurs on.
 */
@property(nonatomic,copy) NSString *vehicleID;

/**
 When this object was created. Deep link objects expire after 24 hours automatically.
 This happens because you probably won't want to keep such an object sitting around
 in perpetuity because it's irrelevant as soon as the trip occurs.
 */
@property(nonatomic,copy,readonly) NSDate *createdAt;

/**
 Generates a deep-link URL for an ArrivalAndDeparture object.
 Suitable for sharing an arrival time with another person.
 */
@property(nonatomic,copy,readonly) NSURL *deepLinkURL;

/**
 Creates an OBATripDeepLink object

 @param arrivalAndDeparture An arrival and departure object, such as what can be retrieved from the Stop Controller
 @param region The app's current region
 @return An initialized OBATripDeepLink object
 */
- (instancetype)initWithArrivalAndDeparture:(nullable OBAArrivalAndDepartureV2*)arrivalAndDeparture region:(nullable OBARegionV2*)region;
@end

NS_ASSUME_NONNULL_END
