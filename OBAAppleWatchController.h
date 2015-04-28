//
//  OBAAppleWatchController.h
//  org.onebusaway.iphone
//
//  Created by Shannon Young on 4/6/15.
//  Copyright (c) 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OBAApplicationDelegate;

@interface OBAAppleWatchController : NSObject

+ (instancetype)sharedInstance;

- (void)handleWatchKitExtensionRequestForAppDelegate:(OBAApplicationDelegate *)appDelegate
                                            userInfo:(NSDictionary *)userInfo
                                               reply:(void (^)(NSDictionary *replyInfo))reply;

@end
