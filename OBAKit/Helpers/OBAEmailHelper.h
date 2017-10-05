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
@property(nonatomic,copy) NSString *messageBody;
@property(nonatomic,copy) NSString *messageBodyText;
- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO currentLocation:(CLLocation*)location registeredForRemoteNotifications:(BOOL)registeredForRemoteNotifications locationAuthorizationStatus:(CLAuthorizationStatus)locationAuthorizationStatus;
- (nullable MFMailComposeViewController*)mailComposerForEmailTarget:(OBAEmailTarget)emailTarget;
- (NSString*)emailAddressForTarget:(OBAEmailTarget)emailTarget;
@end

NS_ASSUME_NONNULL_END
