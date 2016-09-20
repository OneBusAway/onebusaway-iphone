//
//  OBAStrings.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OBAStrings : NSObject

/**
 The text 'Cancel'.
 */
+ (NSString*)cancel;

/**
 The text 'Delete'.
 */
+ (NSString*)delete;

/**
 The text 'Dismiss'. Used on alerts.
 iOS tends to use 'Dismiss' instead of 'OK' on alerts that the user isn't actually agreeing to.
 */
+ (NSString*)dismiss;

/**
 The text 'Edit'.
 */
+ (NSString*)edit;

/**
 The text 'OK'.
 */
+ (NSString*)ok;

/**
 The text 'Save'.
 */
+ (NSString*)save;

/**
 The explanatory text displayed when a non-realtime trip is displayed on-screen.
 */
+ (NSString*)scheduledDepartureExplanation;

@end
