//
//  OBAEmailHelper.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 7/10/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import MessageUI;
@import CoreLocation;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, OBAEmailTarget) {
    OBAEmailTargetTransitAgency,
    OBAEmailTargetAppDevelopers,
};

@class OBAModelDAO;

@interface OBAEmailHelper : NSObject
- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO currentLocation:(CLLocation*)currentLocation;
- (nullable MFMailComposeViewController*)mailComposerForEmailTarget:(OBAEmailTarget)emailTarget;
@end

NS_ASSUME_NONNULL_END
