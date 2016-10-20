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

@class OBAModelDAO;

@interface OBAEmailHelper : NSObject
+ (NSString*)messageBodyForModelDAO:(OBAModelDAO*)modelDAO currentLocation:(CLLocation*)location;
+ (nullable MFMailComposeViewController*)mailComposeViewControllerForModelDAO:(OBAModelDAO*)modelDAO currentLocation:(CLLocation*)location;
@end

NS_ASSUME_NONNULL_END
